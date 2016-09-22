require 'plan_runner'

# Start plan runner, except:
#   * when testing
#   * running rake, such as 'rake db:migrate'
unless (File.basename($0) == 'rake') or Rails.env.test?
  PlanRunner.instance.start
end
