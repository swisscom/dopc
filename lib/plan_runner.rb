require 'singleton'
require 'set'

# Public methods on planner may be called in parallel from Rails requests.
class PlanRunner

  include Singleton

  def initialize(num_workers = Rails.configuration.num_workers)
    @num_workers = num_workers
    @log = Rails.logger
    @workers = Set.new
    @tasks = Queue.new
    @worker_tasks = Queue.new
    @thread = start_background
  end

  def start
    @tasks << {cmd: :start}
  end

  def stop
    @tasks << {cmd: :stop}
  end

  def running?
    not @workers.empty?
  end

  def update
    enqueue_new
  end

  private

  def start_background
    Thread.new do
      run
    end
  end

  def run
    loop do
      begin
        task = @tasks.pop
        case task[:cmd]
        when :start
          if @workers.empty?
            @worker_tasks.clear
            self.fail_running
            self.restore_worker_tasks
            @num_workers.times { @workers << PlanWorker.new(@worker_tasks, @tasks) }
          end
        when :stop
          @worker_tasks.clear
          @workers.size.times { @worker_tasks << {cmd: :stop} }
        when :rm_worker
          @workers.remove task[:arg]
        end
      rescue => e
        @log.error('Plan runner') {"continuing after unexpected error: #{e.message}: #{e.backtrace.join('\n')}"}
      end
    end
  end

  def enqueue_new
    PlanExecution.transaction do
      PlanExecution.where(status: :new).each do |pe|
        if can_run?(pe)
          pe.status_queued!
          @worker_tasks << {cmd: :run, arg: pe}
          @log.info('Plan runner') {"queued plan execution #{pe.id}"}
        end
      end
    end
  end

  def can_run?(pe)
    PlanExecution.transaction do
      PlanExecution.where(plan: pe.plan, status: :running).empty? and
        PlanExecution.where(plan: pe.plan, status: :queued).empty?
    end
  end

  def fail_running
    PlanExecution.transaction do
      PlanExecution.where(status: :running).each do |pe|
        pe.status_failed!
        @log.info('Plan runner') {"clearing running execution #{pe.id}, setting to failed"}
      end
    end
  end

  def restore_worker_tasks
    PlanExecution.transaction do
      PlanExecution.where(status: :queued).each do |pe|
        @worker_tasks << {cmd: :run, arg: pe}
      end
    end
  end

end
