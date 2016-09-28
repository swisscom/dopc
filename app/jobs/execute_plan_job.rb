class ExecutePlanJob < ApplicationJob

  def perform(plan_execution)
    plan_execution.run
  end

end
