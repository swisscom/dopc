require 'test_helper'

class ExecutionsControllerTest < ActionDispatch::IntegrationTest

  self.use_transactional_tests = true

  setup do
    setup_tmp
    mock_cache
    mock_dopv
    mock_dopi
    add_plan('hello_world')
  end

  teardown do
    teardown_tmp
  end

  test 'start setup' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'setup'}, as: :json
    data = JSON.parse(@response.body)
    assert_response :created
    assert_equal 4, data['id']
  end

#  test 'start deploy' do
#    post '/api/v1/executions', params: {plan: 'hello_world', task: 'deploy'}, as: :json
#    data = JSON.parse(@response.body)
#    assert_response :created
#    assert_equal 4, data['id']
#  end
#
#  test 'start run' do
#    post '/api/v1/executions', params: {plan: 'hello_world', task: 'run'}, as: :json
#    data = JSON.parse(@response.body)
#    assert_response :created
#    assert_equal 4, data['id']
#  end
#
#  test 'start undeploy' do
#    post '/api/v1/executions', params: {plan: 'hello_world', task: 'undeploy'}, as: :json
#    data = JSON.parse(@response.body)
#    assert_response :created
#    assert_equal 4, data['id']
#  end
#
#  test 'invalid task' do
#    post '/api/v1/executions', params: {plan: 'hello_world', task: 'invalid'}, as: :json
#    data = JSON.parse(@response.body)
#    assert_response :unprocessable_entity
#    assert_not_empty data['error']
#  end

end
