require 'test_helper'

class PlansTest < ActionDispatch::IntegrationTest

  setup do
    setup_tmp
    mock_cache
  end

  teardown do
    teardown_tmp
  end

  test 'list no plans' do
    get '/api/v1/plans', as: :json
    data = JSON.parse(@response.body)
    assert_response :success
    assert_kind_of Array, data['plans']
    assert_empty data['plans']
  end

  test 'list plan' do
    post '/api/v1/plans', params: {content: encode_plan('hello_world')}, as: :json
    data = JSON.parse(@response.body)
    assert_response :created
    assert_equal 'hello_world', data['name']
    get '/api/v1/plans', as: :json
    data = JSON.parse(@response.body)
    assert_response :success
    assert_equal 1, data['plans'].size
    assert_equal 'hello_world', data['plans'][0]['name']
  end

  test 'add plan' do
    post '/api/v1/plans', params: {content: encode_plan('hello_world')}, as: :json
    data = JSON.parse(@response.body)
    assert_response :created
    assert_equal 'hello_world', data['name']
  end

  test 'can not add plan twice' do
    post '/api/v1/plans', params: {content: encode_plan('hello_world')}, as: :json
    data = JSON.parse(@response.body)
    assert_response :created
    post '/api/v1/plans', params: {content: encode_plan('hello_world')}, as: :json
    data = JSON.parse(@response.body)
    assert_response :bad_request
    assert_not_empty data['error']
  end

  test 'can not add plan with invalid content' do
    post '/api/v1/plans', params: {content: 'abc'}, as: :json
    data = JSON.parse(@response.body)
    assert_response :unprocessable_entity
    assert_not_empty data['error']
  end

  test 'can not add invalid plan' do
    post '/api/v1/plans', params: {content: encode_plan('invalid')}, as: :json
    data = JSON.parse(@response.body)
    assert_response :bad_request
    assert_not_empty data['error']
  end

  test 'delete plan' do
    post '/api/v1/plans', params: {content: encode_plan('hello_world')}, as: :json
    data = JSON.parse(@response.body)
    assert_response :created
    assert_equal 'hello_world', data['name']
    delete '/api/v1/plans/hello_world', as: :json
    assert_response :success
    assert_equal 'hello_world', data['name']
  end

  test 'can not delete non-existent plan' do
    delete "/api/v1/plans/does_not_exist", as: :json
    data = JSON.parse(@response.body)
    assert_response :not_found
    assert_not_empty data['error']
  end

  test 'can not delete plan twice' do
    post '/api/v1/plans', params: {content: encode_plan('hello_world')}, as: :json
    data = JSON.parse(@response.body)
    assert_response :created
    assert_equal 'hello_world', data['name']
    delete '/api/v1/plans/hello_world', as: :json
    assert_response :success
    assert_equal 'hello_world', data['name']
    delete '/api/v1/plans/hello_world', as: :json
    data = JSON.parse(@response.body)
    assert_response :not_found
    assert_not_empty data['error']
  end

  test 'get added plan' do
    post '/api/v1/plans', params: {content: encode_plan('hello_world')}, as: :json
    data = JSON.parse(@response.body)
    assert_response :created
    assert_equal 'hello_world', data['name']
    get '/api/v1/plans/hello_world', as: :json
    data = JSON.parse(@response.body)
    assert_response :success
    # When the API creates a plan from the YAML the content is slightly
    # modified, so compare YAML contents, not strings
    plan_orig = YAML.load(read_plan('hello_world'))
    plan_dopc = YAML.load(decode_plan(data['content']))
    assert_equal plan_orig, plan_dopc
  end

  test 'can not get non-existent plan' do
    get "/api/v1/plans/does_not_exist", as: :json
    assert_response :not_found
  end

  test 'update added plan' do
    post '/api/v1/plans', params: {content: encode_plan('hello_world')}, as: :json
    data = JSON.parse(@response.body)
    assert_response :created
    assert_equal 'hello_world', data['name']
    put '/api/v1/plans', params: {content: encode_plan('hello_world')}, as: :json
    data = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'hello_world', data['name']
  end

  test 'when updating plan names must match' do
    post '/api/v1/plans', params: {content: encode_plan('hello_world')}, as: :json
    data = JSON.parse(@response.body)
    assert_response :created
    assert_equal 'hello_world', data['name']
    put '/api/v1/plans', params: {content: encode_plan('hello_world_2')}, as: :json
    data = JSON.parse(@response.body)
    assert_response :bad_request
    assert_not_empty data['error']
  end

  test 'can not update non-existent plan' do
    put '/api/v1/plans', params: {content: encode_plan('hello_world')}, as: :json
    data = JSON.parse(@response.body)
    assert_response :bad_request
    assert_not_empty data['error']
  end

  test 'get versions' do
    post '/api/v1/plans', params: {content: encode_plan('hello_world')}, as: :json
    data = JSON.parse(@response.body)
    assert_response :created
    assert_equal 'hello_world', data['name']
    put '/api/v1/plans', params: {content: encode_plan('hello_world')}, as: :json
    data = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'hello_world', data['name']
    get '/api/v1/plans/hello_world/versions', as: :json
    data = JSON.parse(@response.body)
    assert_response :success
    assert_kind_of Array, data['versions']
    assert_equal 2, data['versions'].size
    assert_not_empty data['versions'].first
  end

end
