class Dopc::PlanRunJob << ApplicationJob

  queue :default

  def perform(plan)
  end

end
