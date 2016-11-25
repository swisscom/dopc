require 'dop_common'
require 'dopv'
require 'dopi'
require 'log'

require 'fileutils'
require 'yaml'

class PlanExecution < ApplicationRecord

  enum status: [:new, :queued, :running, :done, :failed], _prefix: true
  enum task: [:setup, :run, :deploy, :undeploy, :teardown], _prefix: true

  def self.log
    Delayed::Worker.logger
  end

  def self.log_dir
    File.join(Rails.root, 'log', 'executions_' + Rails.env)
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
    Log.set_loggers(log)
    self.status_running!
    self.update(started_at: Time.now)
    log.info('Execution started')
    case self[:task]
    when 'setup'
      dopv_deploy
      dopi_run
    when 'teardown'
      dopv_undeploy
      Dopi.reset(self[:plan], true)
    when 'deploy'
      dopv_deploy
    when 'run'
      dopi_run
    when 'undeploy'
      dopv_undeploy
    else
      raise "Invalid task: #{self[:task]}"
    end
    self.status_done!
    log.info('Execution done')
  rescue Exception => e
    self.status_failed!
    log.error("Execution failed: #{e.message}: #{e.backtrace.join('\n')}")
  ensure
    self.update(finished_at: Time.now)
    Log.set_loggers(Delayed::Worker.logger, true)
    self.class.schedule
  end

  def to_hash
    {id: self[:id], plan: self[:plan], task: self[:task], stepset: self[:stepset], rmdisk: self[:rmdisk], run_for_nodes: self[:run_for_nodes], status: self[:status], created_at: self[:created_at], updated_at: self[:updated_at], started_at: self[:started_at], finished_at: self[:finished_at]}
  end

  def read_log
    File.file?(log_file) ? File.read(log_file) : ''
  end

  def delete_log
    Util.rm_ensure(log_file)
  end

  private

  def log_file
    File.join(self.class.log_dir, self.id.to_s + '.log')
  end

  def log
    FileUtils.mkdir_p(File.dirname(log_file))
    @log ||= Logger.new(log_file)
  end

  def cache
    DopCommon::PlanStore.new(Dopi.configuration.plan_store_dir)
  end

  def dopv_deploy
    log.info('Deploying with DOPv')
    Dopv.deploy(self[:plan])
  end

  def dopv_undeploy
    log.info('Undeploying with DOPv')
    if self[:rmdisk]
      Dopv.undeploy(self[:plan], true)
    else
      Dopv.undeploy(self[:plan])
    end
  end

  def dopi_run
    log.info('Running DOPi')
    options = {}
    options.merge!({step_set: self[:stepset]}) if self[:stepset]
    if self[:run_for_nodes]
      run_options = YAML::load(self[:run_for_nodes])
      options[:run_for_nodes] = run_options
    end
    config_file = Dopi.configuration.config_file
    if config_file and File.file?(config_file) and !Rails.env.test?
      config = YAML::load_file(config_file)
      Dopi.configure = config
      log.debug("Loaded DOPi configuration from #{config_file}")
    end
    Dopi.run(self[:plan], options) do |plan|
      # Avoid installing signal handler by passing block
    end
  end

end
