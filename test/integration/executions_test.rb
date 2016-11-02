require 'test_helper'

class ExecutionsTest < ActionDispatch::IntegrationTest

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
    assert_equal 1, id
    get "/api/v1/executions/#{id}", as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    # Must not check status, could be either new or already queued
    assert_equal id, data['id']
    assert_equal 'hello_world', data['plan']
    assert_equal 'setup', data['task']
    assert_equal nil, data['stepset']
    assert_equal nil, data['log']
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
    assert_equal nil, execution
  end

  test 'remove execution' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'setup'}, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    id = data['id']
    delete "/api/v1/executions/#{id}", as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal id, data['id']
    assert_equal 'hello_world', data['plan']
    assert_equal 'setup', data['task']
  end

end
