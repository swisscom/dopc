namespace :dopc do

  desc "Force scheduling new executions"
  task schedule: :environment do
    PlanExecution.schedule
  end

end

namespace :log do

  namespace :clear do

    desc "Truncates all logs (except executions)"
    task all: :environment do
      ENV['LOGS'] = 'all'
      Rake::Task['log:clear'].invoke
    end

    desc "Deletes all execution log files for which no execution exists"
    task exe: :environment do
      ids = PlanExecution.ids
      Dir[File.join(PlanExecution.log_dir, '*.log')].each do |f|
        id = File.basename(f).gsub(/\.log$/, '').to_i
        Util.rm_ensure(f) unless ids.include?(id)
      end
    end

  end

end
