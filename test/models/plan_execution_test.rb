require 'test_helper'

class PlanExecutionTest < ActiveSupport::TestCase

  self.use_transactional_tests = true
  fixtures :plan_executions

  test 'fixtures count' do
    assert_equal 1, PlanExecution.count
  end

  test 'add plan' do
    new = PlanExecution.create(plan: 'myplan', task: :setup, stepset: 'default', status: :new)
    id = new.id
    exec = PlanExecution.find(id)
    assert_equal 2, exec.id
    assert_equal 'myplan', exec.plan
    assert_equal 'setup', exec.task
    assert_equal true, exec.task_setup?
    assert_equal 'default', exec.stepset
    assert_equal 'new', exec.status
    assert_equal true, exec.status_new?
  end



end
