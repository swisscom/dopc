require 'test_helper'
require 'plan_worker'
require 'plan_execution_mock'

class PlanWorkerTest < ActiveSupport::TestCase

  test 'next id' do
    PlanWorker.class_variable_set(:@@next_id, 0)
    pw = PlanWorker.new(Queue.new, Queue.new)
    assert_equal 0, pw.id
    pw = PlanWorker.new(Queue.new, Queue.new)
    assert_equal 1, pw.id
    PlanWorker.new(Queue.new, Queue.new)
    pw = PlanWorker.new(Queue.new, Queue.new)
    assert_equal 3, pw.id
  end

  test 'run' do
    pe = PlanExecutionMock.new
    t = Queue.new
    t << {cmd: :run, arg: pe}
    t << {cmd: :stop}
    r = Queue.new
    pw = PlanWorker.new(t, r)
    assert_equal({cmd: :worker_stopped, arg: pw}, r.pop)
    assert_equal true, pe.has_run
  end

  test 'run all' do
    t = Queue.new
    pes = []
    5.times do
      pe = PlanExecutionMock.new
      pes << pe
      t << {cmd: :run, arg: pe}
    end
    t << {cmd: :stop}
    r = Queue.new
    pw = PlanWorker.new(t, r)
    assert_equal({cmd: :worker_stopped, arg: pw}, r.pop)
    pes.each do |pe|
      assert_equal true, pe.has_run
    end
  end

  test 'stop before run' do
    t = Queue.new
    t << {cmd: :stop}
    pe = PlanExecutionMock.new
    t << {cmd: :run, arg: pe}
    r = Queue.new
    pw = PlanWorker.new(t, r)
    assert_equal({cmd: :worker_stopped, arg: pw}, r.pop)
    assert_equal false, pe.has_run
  end

  test 'stop' do
    t = Queue.new
    t << {cmd: :stop}
    r = Queue.new
    pw = PlanWorker.new(t, r)
    assert_equal({cmd: :worker_stopped, arg: pw}, r.pop)
  end

  test 'continue after error' do
    pe1 = PlanExecutionFailMock.new
    pe2 = PlanExecutionMock.new
    t = Queue.new
    t << {cmd: :run, arg: pe1}
    t << {cmd: :run, arg: pe2}
    t << {cmd: :stop}
    r = Queue.new
    pw = PlanWorker.new(t, r)
    assert_equal({cmd: :worker_stopped, arg: pw}, r.pop)
    assert_equal true, pe1.has_started
    assert_equal false, pe1.has_run
    assert_equal true, pe2.has_run
  end

end
