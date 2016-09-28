namespace :dopc do

  desc "Force scheduling new executions"
  task schedule: :environment do
    PlanExecution.schedule
  end

end
