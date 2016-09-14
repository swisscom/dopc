require 'cache'
require 'dopv'
require 'dopi'

class PlanExecution < ApplicationRecord

  enum status: [:new, :queued, :running, :done, :failed], _prefix: true
  enum task: [:setup, :run, :deploy, :undeploy], _prefix: true

  def run
    self.status_running!
    log.info("Started execution #{self.id}")
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
    log.info("Done execution #{self.id}")
  rescue => e
    self.status_failed!
    self.update(log: "Error while executing the plan")
    log.error("Execution #{self.id} failed: #{e.message}: #{e.backtrace.join('\n')}")
  end

  private

  def log
    @log ||= Rails.logger
  end

  def cache
    @cache ||= Cache.plan_cache
  end

  def dopv_deploy
    log.info("Execution #{self.id}: Deploying with DOPv")
    Dopv.logger = log
    plan_file = cache.yaml_file(self[:plan])
    plan = Dopv::load_plan(plan_file)
    vol_db = Dopv::load_data_volumes_db("disks-#{self.id}.db")
    Dopv::run_plan(plan, vol_db, :deploy)
  end

  def dopv_undeploy
    log.info("Execution #{self.id}: Undeploying with DOPv")
    Dopv.logger = log
    plan_file = cache.yaml_file(self[:plan])
    plan = Dopv::load_plan(plan_file)
    vol_db = Dopv::load_data_volumes_db("disks-#{self.id}.db")
    Dopv::run_plan(plan, vol_db, :undeploy)
  end

  def dopi_run
    log.info("Execution #{self.id}: Running DOPi")
    plan = Dopi.load_plan(self[:plan])
    options = {}
    self[:stepset] ? options.merge!({step_set: self[:stepset]}) :
    Dopi.run_plan(plan, options)
  end

end