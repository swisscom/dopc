require 'plan_runner'

unless (File.basename($0) == 'rake') or Rails.env.test?
  PlanRunner.instance
end
