require 'test_helper'

class JsonTest < ActionDispatch::IntegrationTest

  setup do
    setup_auth
  end

  test 'accept json' do
    get '/api/v1/ping', headers: {'Accept' => 'application/json', 'Content-Type' => 'application/json'}.merge(auth_header)
    assert_response :success
  end

  test 'accept any' do
    get '/api/v1/ping', headers: {'Accept' => '*/*', 'Content-Type' => 'application/json'}.merge(auth_header)
    assert_response :success
  end

  test 'accept any application' do
    get '/api/v1/ping', headers: {'Accept' => 'application/*', 'Content-Type' => 'application/json'}.merge(auth_header)
    assert_response :success
  end

  test 'accept json amongst others' do
    get '/api/v1/ping', headers: {'Accept' => 'text/plain, application/json', 'Content-Type' => 'application/json'}.merge(auth_header)
    assert_response :success
  end

  test 'do not accept text' do
    get '/api/v1/ping', headers: {'Accept' => 'text/plain', 'Content-Type' => 'application/json'}.merge(auth_header)
    data = JSON.parse(@response.body)
    assert_response :not_acceptable
    assert_equal @response.content_type, 'application/json'
    assert_not_empty data['error']
  end

  test 'can send json' do
    get '/api/v1/ping', headers: {'Accept' => 'application/json', 'Content-Type' => 'application/json'}.merge(auth_header)
    assert_response :success
  end

  test 'can not send text' do
    get '/api/v1/ping', headers: {'Accept' => 'application/json', 'Content-Type' => 'text/plain'}.merge(auth_header)
    data = JSON.parse(@response.body)
    assert_response :unsupported_media_type
    assert_equal @response.content_type, 'application/json'
    assert_not_empty data['error']
  end

  test 'can not send empty' do
    get '/api/v1/ping', headers: {'Accept' => 'application/json', 'Content-Type' => ''}.merge(auth_header)
    data = JSON.parse(@response.body)
    assert_response :unsupported_media_type
    assert_equal @response.content_type, 'application/json'
    assert_not_empty data['error']
  end

end
