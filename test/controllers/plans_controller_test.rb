require 'test_helper'
require 'base64'

class PlansControllerTest < ActionDispatch::IntegrationTest

  setup do
    @tmp = Dir.mktmpdir
    Rails.configuration.cache_dir = @tmp
    @plan = File.read(Rails.root.join('test', 'fixtures', 'plans', 'hello_world.yaml'))
    @plan_name = 'hello_world'
  end

  teardown do
    FileUtils.remove_entry @tmp
  end

  test 'list no plans' do
    get '/api/v1/plans', as: :json
    data = JSON.parse(@response.body)
    assert_response :success
    assert_kind_of Array, data['plans']
    assert_empty data['plans']
  end

  test 'list plan' do
    post '/api/v1/plans', params: {content: Base64.encode64(@plan)}, as: :json
    data = JSON.parse(@response.body)
    assert_response :success
    assert_equal @plan_name, data['name']
    get '/api/v1/plans', as: :json
    data = JSON.parse(@response.body)
    assert_response :success
    assert_equal 1, data['plans'].size
    assert_equal @plan_name, data['plans'][0]['name']
  end

  test 'add plan' do
    post '/api/v1/plans', params: {content: Base64.encode64(@plan)}, as: :json
    data = JSON.parse(@response.body)
    assert_response :success
    assert_equal @plan_name, data['name']
  end

  test 'can not add plan twice' do
    post '/api/v1/plans', params: {content: Base64.encode64(@plan)}, as: :json
    data = JSON.parse(@response.body)
    assert_response :success
    post '/api/v1/plans', params: {content: Base64.encode64(@plan)}, as: :json
    data = JSON.parse(@response.body)
    assert_response :unprocessable_entity
    assert_not_empty data['error']
  end

  test 'can not add invalid plan' do
    post '/api/v1/plans', params: {content: 'abc'}, as: :json
    data = JSON.parse(@response.body)
    assert_response :unprocessable_entity
    assert_not_empty data['error']
  end

  test 'delete plan' do
    post '/api/v1/plans', params: {content: Base64.encode64(@plan)}, as: :json
    data = JSON.parse(@response.body)
    assert_response :success
    assert_equal @plan_name, data['name']
    delete "/api/v1/plans/#{@plan_name}", as: :json
    assert_response :success
    assert_equal @plan_name, data['name']
  end

  test 'can not delete non-existent plan' do
    delete '/api/v1/plans/test', as: :json
    data = JSON.parse(@response.body)
    assert_response :not_found
    assert_not_empty data['error']
  end

  test 'check added plan' do
    post '/api/v1/plans', params: {content: Base64.encode64(@plan)}, as: :json
    data = JSON.parse(@response.body)
    assert_response :success
    assert_equal @plan_name, data['name']
    get "/api/v1/plans/#{@plan_name}/check", as: :json
    data = JSON.parse(@response.body)
    assert_response :success
    assert_equal true, data['valid']
  end

end
