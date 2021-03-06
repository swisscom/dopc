require 'test_helper'

class ExecutionsTest < ActionDispatch::IntegrationTest

  self.use_transactional_tests = true

  setup do
    setup_tmp
    mock_cache
    mock_logdir
    mock_dopv
    setup_auth
    add_plan('hello_world')
  end

  teardown do
    teardown_tmp
  end

  test 'start deployment' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'deploy'}, headers: auth_header, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    id = data['id']
    assert_equal 1, id
    get "/api/v1/executions/#{id}", headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal id, data['id']
    assert_equal 'hello_world', data['plan']
    assert_equal 'deploy', data['task']
    assert_equal 'new', data['status']
    assert_not_empty data['created_at']
    assert_not_empty data['updated_at']
  end

  test 'start run' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'run', run_options: {step_set: 'default'}}, headers: auth_header, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    id = data['id']
    assert_equal 1, id
    get "/api/v1/executions/#{id}", headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal id, data['id']
    assert_equal 'hello_world', data['plan']
    assert_equal 'run', data['task']
    assert_equal 'new', data['status']
    assert_equal 'default', data['run_options']['step_set']
    assert_not_empty data['created_at']
    assert_not_empty data['updated_at']
  end

  test 'start setup' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'setup', run_options: {step_set: 'default'}}, headers: auth_header, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    id = data['id']
    assert_equal 1, id
    get "/api/v1/executions/#{id}", headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal id, data['id']
    assert_equal 'hello_world', data['plan']
    assert_equal 'setup', data['task']
    assert_equal 'new', data['status']
    assert_equal 'default', data['run_options']['step_set']
    assert_not_empty data['created_at']
    assert_not_empty data['updated_at']
  end

  test 'start undeployment' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'undeploy', run_options: {rmdisk: true}}, headers: auth_header, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    id = data['id']
    assert_equal 1, id
    get "/api/v1/executions/#{id}", headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal id, data['id']
    assert_equal 'hello_world', data['plan']
    assert_equal 'undeploy', data['task']
    assert_equal 'new', data['status']
    assert_equal true, data['run_options']['rmdisk']
    assert_not_empty data['created_at']
    assert_not_empty data['updated_at']
  end

  test 'missing plan' do
    post '/api/v1/executions', params: {task: 'deploy'}, headers: auth_header, as: :json
    assert_response :unprocessable_entity
    data = JSON.parse(@response.body)
    assert_not_empty data['error']
  end

  test 'invalid plan name type' do
    post '/api/v1/executions', params: {plan: 123, task: 'setup'}, headers: auth_header, as: :json
    assert_response :unprocessable_entity
    data = JSON.parse(@response.body)
    assert_not_empty data['error']
  end

  test 'missing task' do
    post '/api/v1/executions', params: {plan: 'hello_world'}, headers: auth_header, as: :json
    assert_response :unprocessable_entity
    data = JSON.parse(@response.body)
    assert_not_empty data['error']
  end

  test 'invalid task name type' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: false}, headers: auth_header, as: :json
    assert_response :unprocessable_entity
    data = JSON.parse(@response.body)
    assert_not_empty data['error']
  end

  test 'invalid task' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'invalid'}, headers: auth_header, as: :json
    assert_response :unprocessable_entity
    data = JSON.parse(@response.body)
    assert_not_empty data['error']
  end

  test 'invalid stepset name type' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'run', run_options: {step_set: 0.1}}, headers: auth_header, as: :json
    assert_response :unprocessable_entity
    data = JSON.parse(@response.body)
    assert_not_empty data['error']
  end

  test 'illegal stepset' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'deploy', run_options: {step_set: 'default2'}}, headers: auth_header, as: :json
    assert_response :unprocessable_entity
    data = JSON.parse(@response.body)
    assert_not_empty data['error']
  end

  test 'invalid rmdisk type' do
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'undeploy', run_options: {rmdisk: 'true'}}, headers: auth_header, as: :json
    assert_response :unprocessable_entity
    data = JSON.parse(@response.body)
    assert_not_empty data['error']
  end

  test 'list executions' do
    get '/api/v1/executions', headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    execution = data.first
    assert_nil execution
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
    assert_empty data.collect{|e| e['id']} - ids
  end

  test 'no execution found to remove' do
    delete "/api/v1/executions", params: {statuses: ['done']}, headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_empty data
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
   assert_equal 'new', data['status']
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
    assert_equal 'new', data['status']
    Delayed::Worker.new.work_off
    get "/api/v1/executions/#{id}", headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 'done', data['status']
  end

  test 'plan run fails' do
    remove_plan('hello_world')
    add_plan('fail')
    post '/api/v1/executions', params: {plan: 'fail', task: 'run'}, headers: auth_header, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    id = data['id']
    Delayed::Worker.new.work_off
    get "/api/v1/executions/#{id}", headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 'failed', data['status']
  end

  test 'fail to deploy a plan' do
    mock_dopv_fail
    post '/api/v1/executions', params: {plan: 'hello_world', task: 'deploy'}, headers: auth_header, as: :json
    assert_response :created
    data = JSON.parse(@response.body)
    id = data['id']
    get "/api/v1/executions/#{id}", headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 'new', data['status']
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
    assert_equal 'new', data['status']
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
    delete '/api/v1/executions', params: {statuses: ['new']}, headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 2, data.size
    get '/api/v1/executions', headers: auth_header, as: :json
    assert_response :success
    data = JSON.parse(@response.body)
    assert_empty data
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
