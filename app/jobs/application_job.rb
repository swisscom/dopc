class ApplicationJob < ActiveJob::Base

  def log
    Delayed::Worker.logger
  end

end
