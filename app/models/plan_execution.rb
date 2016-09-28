require 'dopv'
require 'dopi'

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

  def run
    self.status_running!
    log.info("Execution #{self.id}") {'started'}
    case self[:task]
    when 'setup'
      dopv_deploy
      dopi_run
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
    log.info("Execution #{self.id}") {'done'}
  rescue => e
    self.status_failed!
    self.update(log: "Error while executing the plan")
    log.error("Execution #{self.id}") {"failed: #{e.message}: #{e.backtrace.join('\n')}"}
  ensure
    self.class.schedule
  end

  def to_hash
    {id: self[:id], plan: self[:plan], task: self[:task], stepset: self[:stepset], status: self[:status], log: self[:log]}
  end

  private

  def cache
    DopCommon::PlanCache.new(Dopi.configuration.plan_cache_dir)
  end

  def log
    Delayed::Worker.logger
  end

  def dopv_deploy
    log.info("Execution #{self.id}") {'deploying with DOPv'}
    Dopv.logger = log
    plan_file = cache.yaml_file(self[:plan])
    plan = Dopv::load_plan(plan_file)
    vol_db = Dopv::load_data_volumes_db("disks-#{self.id}.db")
    Dopv::run_plan(plan, vol_db, :deploy)
  end

  def dopv_undeploy
    log.info("Execution #{self.id}") {'undeploying with DOPv'}
    Dopv.logger = log
    plan_file = cache.yaml_file(self[:plan])
    plan = Dopv::load_plan(plan_file)
    vol_db = Dopv::load_data_volumes_db("disks-#{self.id}.db")
    Dopv::run_plan(plan, vol_db, :undeploy)
  end

  def dopi_run
    log.info("Execution #{self.id}") {'running DOPi'}
    plan = Dopi.load_plan(self[:plan])
    options = {}
    self[:stepset] ? options.merge!({step_set: self[:stepset]}) :
    Dopi.run_plan(plan, options)
  end

end
