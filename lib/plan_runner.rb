require 'singleton'
require 'plan_run_status'

class PlanRunner

  include Singleton

  def initialize
    @jobs = Queue.new
    @workers = []
    reset_states
    fill_queue
    start_workers
  end

  def fill_queue
    PlanRun.where(status: PlanRunStatus::NEW) do |run|
      @jobs << run
    end
  end

  def reset_states
    PlanRun.where(status: PlanRunStatus::RUNNING) do |run|
      run.status = PlanRunStatus::ABORTED
      run.save
    end
  end

  def start_worker
    @workers << Thread.new do
      while true
        begin
          job = @jobs.pop
        rescue
          # Do not abort worker on error
        end
        job.run
      end
    end
  end

  def start_workers(num = 2)
    for i in 1..num
      start_worker
    end
  end

  def update(job)
    @jobs << job
  end

end
