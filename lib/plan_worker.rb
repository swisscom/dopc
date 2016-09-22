class PlanWorker

  attr_reader :id

  def initialize(tasks, planner_tasks)
    @id = next_id
    @log = Rails.logger
    @tasks = tasks
    @planner_tasks = planner_tasks
    @thread = start_background
  end

  private

  def next_id
    @@next_id ||= 0
    id = @@next_id
    @@next_id += 1
    return id
  end

  def start_background
    Thread.new do
      run
    end
  end

  def run
    run = true
    while run
      begin
        task = @tasks.pop
        case task[:cmd]
        when :run
          task[:arg].run
        when :stop
          @planner_tasks << {cmd: :worker_stopped, arg: self}
          run = false
        end
      rescue => e
        @log.error("Worker #{@id}") {"continuing after unexpected error: #{e.message}: #{e.backtrace.join('\n')}"}
      end
    end
  end

end
