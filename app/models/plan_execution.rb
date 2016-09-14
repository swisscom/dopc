require 'dop_common/plan_cache'
require 'dopv'
require 'dopi'

class PlanExecution < ApplicationRecord

  enum status: [:new, :queued, :running, :done, :failed], _prefix: true
  enum task: [:setup, :run, :deploy, :undeploy], _prefix: true

  def run
    self.status_running!
    log.info("Started execution #{self.id}")
    case self[:task]
    when :setup
      dopv_deploy
      dopi_run
    when :deploy
      dopv_deploy
    when :run
      dopi_run
    when :undeploy
      dopv_undeploy
    else
      raise 'Invalid task'
    end
    self.status_done!
    log.info("Done execution #{self.id}")
  rescue => e
    self.status_failed!
    self.update(log: "Exception: #{e.message}")
    self.error("Execution #{self.id} failed: #{e.message}")
  end

  private

  def log
    @log ||= Rails.logger
  end

  def cache
    @cache ||= Cache.get
  end

  def dopv_deploy
    log.info("Execution #{self.id}: Deploying with DOPv")
    Dopv.log(log)
    plan_file = cache.dump_file(self[:plan])
    plan = Dopv::load_plan(plan_file)
    vol_db = Dopv::load_data_volumes_db(...)
    Dopv::run_plan(plan, vol_db, :deploy)
  end

  def dopv_undeploy
    log.info("Execution #{self.id}: Undeploying with DOPv")
    Dopv.log(log)
    plan_file = cache.dump_file(self[:plan])
    plan = Dopv::load_plan(plan_file)
    vol_db = Dopv::load_data_volumes_db("disks-#{self.id}.db")
    Dopv::run_plan(plan, vol_db, :undeploy)
  end

  def dopi_run
    log.info("Execution #{self.id}: Running DOPi")
    plan = Dopi.load_plan(self[:plan])
    options = {}
    self[:stepset] ? options.merge!({step_set: self[:stepset]})
    Dopi.run_plan(plan, options)
  end

end
