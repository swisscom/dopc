require 'test_helper'
require 'mocha/test_unit'

class ExecutionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    setup_tmpcache
    PlanExecutor.instance.stop
    add_plan('hello_world')
  end

  teardown do
    teardown_tmpcache
  end

  test 'start a setup' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'setup'}, as: :json
    data = JSON.parse(@response.body)
    assert_response :created
    assert_equal 1, data['id']
  end

  test 'start a deployment' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'deploy'}, as: :json
    data = JSON.parse(@response.body)
    assert_response :created
    assert_equal 1, data['id']
  end

  test 'start a run' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'run'}, as: :json
    data = JSON.parse(@response.body)
    assert_response :created
    assert_equal 1, data['id']
  end

  test 'start a undeployment' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'undeploy'}, as: :json
    data = JSON.parse(@response.body)
    assert_response :created
    assert_equal 1, data['id']
  end

  test 'invalid task' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'invalid'}, as: :json
    data = JSON.parse(@response.body)
    assert_response :unprocessable_entity
    assert_not_empty data['error']
  end

end
