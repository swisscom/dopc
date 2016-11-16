require 'dop_common'
require 'dopv'
require 'dopi'
require 'log'

require 'tempfile'
require 'fileutils'
require 'stringio'
require 'yaml'

class PlanExecution < ApplicationRecord

  enum status: [:new, :queued, :running, :done, :failed], _prefix: true
  enum task: [:setup, :run, :deploy, :undeploy], _prefix: true

  def self.log
    Delayed::Worker.logger
  end

  def self.schedule
    log.info('Checking for new plan executions')
    PlanExecution.transaction do
      # TODO: Optimize query?
      PlanExecution.where(status: :new).group(:plan).having('id = MIN(id)').each do |pe|
        numQueued = PlanExecution.where(plan: pe.plan, status: :queued).count
        numRunning = PlanExecution.where(plan: pe.plan, status: :running).count
        if numQueued == 0 and numRunning == 0
          pe.status_queued!
          ExecutePlanJob.perform_later(pe)
          log.info("Scheduled execution #{pe.id}")
        end
      end
    end
  end

  def self.remove_statuses
    statuses = self.statuses.keys
    statuses.delete('running')
    statuses
  end

  def run
    buf = StringIO.new
    log = Logger.new(buf)
    Log.set_loggers(log)
    self.status_running!
    log.info('Execution started')
    case self[:task]
    when 'setup'
      dopv_deploy(log)
      dopi_run(log)
    when 'deploy'
      dopv_deploy(log)
    when 'run'
      dopi_run(log)
    when 'undeploy'
      dopv_undeploy(log)
    else
      raise "Invalid task: #{self[:task]}"
    end
    self.status_done!
    log.info('Execution done')
  rescue Exception => e
    self.status_failed!
    log.error("Execution failed: #{e.message}: #{e.backtrace.join('\n')}")
  ensure
    self.update(log: buf.string)
    Log.set_loggers(Rails.logger, true)
    self.class.schedule
  end

  def to_hash
    {id: self[:id], plan: self[:plan], task: self[:task], stepset: self[:stepset], status: self[:status], created_at: self[:created_at], updated_at: self[:updated_at]}
  end

  private

  def cache
    DopCommon::PlanStore.new(Dopi.configuration.plan_store_dir)
  end

  def dopv_deploy(log)
    log.info('Deploying with DOPv')
    plan_content = cache.get_plan_yaml(self[:plan])
    tmp = Tempfile.new('dopc')
    begin
      tmp.write(plan_content)
      tmp.close
      plan = Dopv::load_plan(tmp.path)
      # TODO: where to put disk db file?
      vol_db = Dopv::load_data_volumes_db("disks-#{self.id}.db")
      Dopv::run_plan(plan, vol_db, :deploy)
    ensure
      tmp.unlink
    end
  end

  def dopv_undeploy(log)
    log.info('Undeploying with DOPv')
    plan_content = cache.get_plan_yaml(self[:plan])
    tmp = Tempfile.new('dopc')
    begin
      tmp.write(plan_content)
      tmp.close
      plan = Dopv::load_plan(tmp.path)
      # TODO: where to put disk db file?
      vol_db = Dopv::load_data_volumes_db("disks-#{self.id}.db")
      Dopv::run_plan(plan, vol_db, :undeploy)
    ensure
      tmp.unlink
    end
  end

  def dopi_run(log)
    log.info('Running DOPi')
    options = {}
    options.merge!({step_set: self[:stepset]}) if self[:stepset]
    if Rails.env.test?
      options.merge!({noop: true}) if Rails.env.test?
    else
      config_file = Dopi.configuration.config_file
      if config_file and File.file?(config_file) and !Rails.env.test?
        config = YAML::load_file(config_file)
        Dopi.configure = config
        log.debug("Loaded DOPi configuration from #{config_file}")
      end
    end
    Dopi.run(self[:plan], options) {
      # Avoid installing signal handler by passing block
    }
  end

end
