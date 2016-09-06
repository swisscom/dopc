require 'plan_run_status'

class PlanRun < ApplicationRecord

  def run
    self.status = PlanRunStatus::RUNNING
    # TODO: run plan in dopi/dopv ...
    sleep 1
    self.status = PlanRunStatus::DONE
  rescue Exception => e
    self.status = PlanRunStatus::FAILED
    self.log = e.msg
  ensure
    self.save
  end

end
