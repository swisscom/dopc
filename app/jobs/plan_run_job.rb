class PlanRunJob < ApplicationJob

  queue_as :default

  def perform(plan)
  end

end
