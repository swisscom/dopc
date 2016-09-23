class PlanExecutionMock

  attr_accessor :has_run

  def initialize
    @has_run = false
  end

  def run
    @has_run = true
  end

end

class PlanExecutionFailMock

  attr_accessor :has_run, :has_started

  def initialize
    @has_started = false
    @has_run = false
  end

  def run
    @has_started = true
    raise 'test'
    @has_run = true
  end

end
