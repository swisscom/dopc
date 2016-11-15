Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', "jobs_#{Rails.env}.log"))
#Delayed::Worker.logger = Rails.logger
