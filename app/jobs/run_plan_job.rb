class RunPlanJob < ApplicationJob

  queue_as :default

  def perform(plan)
  end

end
