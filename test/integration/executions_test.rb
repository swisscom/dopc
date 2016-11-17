require 'test_helper'

class ExecutionsTest < ActionDispatch::IntegrationTest

  self.use_transactional_tests = true

  setup do
    setup_tmp
    mock_cache
    mock_dopv
    setup_auth
    add_plan('hello_world')
  end

  teardown do
    teardown_tmp
  end

  test 'start execution' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'setup'}, headers: auth_header, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    id = data['id']
    assert_equal 1, id
    get "/api/v1/executions/#{id}", headers: auth_header, as: :json
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
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'invalid'}, headers: auth_header, as: :json
    assert_response :unprocessable_entity
    data = JSON.parse(@response.body)
    assert_not_empty data['error']
  end

  test 'list executions' do
    get '/api/v1/executions', headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    execution = data['executions'].first
    assert_equal nil, execution
  end

  test 'remove execution' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'setup'}, headers: auth_header, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    id = data['id']
    delete "/api/v1/executions/#{id}", headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal id, data['id']
    assert_equal 'hello_world', data['plan']
    assert_equal 'setup', data['task']
  end

  test 'remove non-existent execution' do
    delete "/api/v1/executions/1", headers: auth_header, as: :json
    assert_response :not_found
  end

  test 'remove all executions' do
    ids = []
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'setup'}, headers: auth_header, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    ids << data['id']
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'setup'}, headers: auth_header, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    ids << data['id']
    delete "/api/v1/executions", params: {statuses: ['new']}, headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_empty data['executions'].collect{|e| e['id']} - ids
  end

  test 'no execution found to remove' do
    delete "/api/v1/executions", params: {statuses: ['done']}, headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_empty data['executions']
  end

  test 'can not remove running executions' do
    delete "/api/v1/executions", params: {statuses: ['running']}, headers: auth_header, as: :json
    assert_response :unprocessable_entity
  end

  test 'invalid statuses' do
    delete "/api/v1/executions", params: {statuses: ['failed', 'invalid']}, headers: auth_header, as: :json
    assert_response :unprocessable_entity
  end

 test 'run a plan' do
   post '/api/v1/executions', params: {plan: 'hello_world', task: 'run'}, headers: auth_header, as: :json
   assert_response :created
   data = JSON.parse(@response.body)
   id = data['id']
   get "/api/v1/executions/#{id}", headers: auth_header, as: :json
   assert_response :success
   data = JSON.parse(@response.body)
   assert_equal 'queued', data['status']
   Delayed::Worker.new.work_off
   get "/api/v1/executions/#{id}", headers: auth_header, as: :json
   assert_response :success
   data = JSON.parse(@response.body)
   assert_equal 'done', data['status']
 end

  test 'deploy a plan' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'deploy'}, headers: auth_header, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    id = data['id']
    get "/api/v1/executions/#{id}", headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 'queued', data['status']
    Delayed::Worker.new.work_off
    get "/api/v1/executions/#{id}", headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 'done', data['status']
  end

  # How to make a DOPi run fail? Can use a valid plan that fails in noop mode?
  #test 'fail to run a plan' do
  #  post '/api/v1/executions', params: {plan: 'hello_world', task: 'run'}, headers: auth_header, as: :json
  #  assert_response :created
  #  data = JSON.parse(@response.body)
  #  id = data['id']
  #  get "/api/v1/executions/#{id}", headers: auth_header, as: :json
  #  assert_response :success
  #  data = JSON.parse(@response.body)
  #  assert_equal 'queued', data['status']
  #  Delayed::Worker.new.work_off
  #  get "/api/v1/executions/#{id}", headers: auth_header, as: :json
  #  assert_response :success
  #  data = JSON.parse(@response.body)
  #  assert_equal 'failed', data['status']
  #end

  test 'fail to deploy a plan' do
    mock_dopv_fail
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'deploy'}, headers: auth_header, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    id = data['id']
    get "/api/v1/executions/#{id}", headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 'queued', data['status']
    Delayed::Worker.new.work_off
    get "/api/v1/executions/#{id}", headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 'failed', data['status']
  end

  test 'run multiple executions' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'setup'}, headers: auth_header, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    id1 = data['id']
    get "/api/v1/executions/#{id1}", headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 'queued', data['status']
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'setup'}, headers: auth_header, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    id2 = data['id']
    get "/api/v1/executions/#{id2}", headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 'new', data['status']
    Delayed::Worker.new.work_off
    get "/api/v1/executions/#{id1}", headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 'done', data['status']
    get "/api/v1/executions/#{id2}", headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 'done', data['status']
  end

  test 'clear an execution' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'setup'}, headers: auth_header, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    id = data['id']
    delete "/api/v1/executions/#{id}", headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal id, data['id']
  end

  test 'clear multiple executions' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'setup'}, headers: auth_header, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    id1 = data['id']
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'setup'}, headers: auth_header, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    id2 = data['id']
    delete '/api/v1/executions', params: {statuses: ['new', 'queued']}, headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 2, data['executions'].size
    get '/api/v1/executions', headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_empty data['executions']
  end

  test 'execute updated plan' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'setup'}, headers: auth_header, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    id = data['id']
    Delayed::Worker.new.work_off
    get "/api/v1/executions/#{id}", headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 'done', data['status']
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'setup'}, headers: auth_header, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    id = data['id']
    Delayed::Worker.new.work_off
    get "/api/v1/executions/#{id}", headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 'done', data['status']
  end

  test 'get log of execution' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'setup'}, headers: auth_header, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    id = data['id']
    Delayed::Worker.new.work_off
    get "/api/v1/executions/#{id}/log", headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_match /Execution started/, data['log']
    assert_match /Execution done/, data['log']
  end

end
