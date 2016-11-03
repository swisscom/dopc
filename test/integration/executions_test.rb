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

  test 'remove non-existent execution' do
    delete "/api/v1/executions/1", as: :json
    assert_response :not_found
  end

  test 'remove all executions' do
    ids = []
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'setup'}, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    ids << data['id']
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'setup'}, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    ids << data['id']
    delete "/api/v1/executions", params: {statuses: ['new']}, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_empty data['executions'].collect{|e| e['id']} - ids
  end

  test 'no execution found to remove' do
    delete "/api/v1/executions", params: {statuses: ['done']}, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_empty data['executions']
  end

  test 'can not remove running executions' do
    delete "/api/v1/executions", params: {statuses: ['running']}, as: :json
    assert_response :unprocessable_entity
  end

  test 'invalid statuses' do
    delete "/api/v1/executions", params: {statuses: ['failed', 'invalid']}, as: :json
    assert_response :unprocessable_entity
  end

end
