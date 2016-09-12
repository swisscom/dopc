class PlanExecution < ApplicationRecord

  enum status: [:new, :queued, :running, :done, :failed], _prefix: true
  enum task: [:setup, :run, :deploy, :undeploy], _prefix: true

  def run
    self.status_running!
    log.info("Started execution #{self.id}")
    # TODO: run plan in dopi/dopv ...
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

end
