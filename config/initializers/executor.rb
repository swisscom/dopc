require 'plan_executor'

# Run plan executor, except:
#   * when testing
#   * running rake, such as 'rake db:migrate'
unless (File.basename($0) == 'rake') or Rails.env.test?
  PlanExecutor.instance.start
end
