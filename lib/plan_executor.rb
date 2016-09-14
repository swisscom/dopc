require 'singleton'
require 'set'

class PlanExecutor

  include Singleton

  def initialize(num_workers = 2)
    @num_workers = num_workers
    @tasks = Queue.new
    @workers = Set.new
    @executor_lock = Mutex.new
    @worker_lock = Mutex.new
    @run_workers = true
    @log = Rails.logger
  end

  def start
    @executor_lock.synchronize do
      if @workers.empty?
        @run_workers = true
        clear_running
        restore_tasks
        enqueue_new
        start_workers
      else
        raise 'Workers are not empty'
      end
    end
  end

  def update
    @executor_lock.synchronize do
      enqueue_new
    end
  end

  def stop(wait=true)
    @executor_lock.synchronize do
      @tasks.clear
      @run_workers = false
      if wait
        @workers.each do |w|
          w.join
        end
      end
    end
  end

  def running?
    not @workers.empty?
  end

  private

  def restore_tasks
    PlanExecution.where(status: :queued).each do |exec|
      @tasks << exec
      @log.info("Re-queuing execution #{exec.id}")
    end
  end

  def clear_running
    PlanExecution.where(status: :running).each do |exec|
      exec.status_failed!
      @log.info("Clearing execution #{exec.id}, setting to failed")
    end
  end

  def enqueue_new
    PlanExecution.where(status: :new).each do |exec|
      if can_run?(exec)
        exec.status_queued!
        @tasks << exec
        @log.info("Queued execution #{exec.id}")
      end
    end
  end

  def start_worker
    @workers << Thread.new do
      while @run_workers
        begin
          task = nil
          task = @tasks.pop(true)
          task.run if task
        rescue ThreadError
          # Queue is empty
          sleep 1
        rescue => e
          # Is it clever to retry in any error case? Could loop indefinitely.
          @log.error("Unexpected error in worker: #{e.message}: #{e.backtrace.join('\n')}")
          task.status_failed! if task
          sleep 1
        end
      end
      @worker_lock.synchronize do
        @workers.delete Thread.current
      end
    end
  end

  def start_workers
    for i in 1..@num_workers
      start_worker
    end
  end

  def can_run?(exec)
    true
  end

end
