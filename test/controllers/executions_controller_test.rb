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

  test 'start execution' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'setup'}, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    id = data['id']
    assert_equal 2, id
    get "/api/v1/executions/#{id}", as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal({'id' => id, 'plan' => 'hello_world', 'task' => 'setup', 'stepset' => nil, 'status' => 'new', 'log' => nil}, data)
  end

  test 'invalid task' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'invalid'}, as: :json
    assert_response :unprocessable_entity
    data = JSON.parse(@response.body)
    assert_not_empty data['error']
  end

  test 'list executions' do
    get '/api/v1/executions', as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    execution = data['executions'].first
    assert_equal({'id' => 1, 'plan' => 'hello_world', 'task' => 'setup', 'stepset' => 'default', 'status' => 'new', 'log' => nil}, execution)
  end

end
