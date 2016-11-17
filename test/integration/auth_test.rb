require 'test_helper'

class AuthTest < ActionDispatch::IntegrationTest

  setup do
    setup_auth
  end

  test 'normal authentication' do
    get '/api/v1/ping', headers: {'Authorization': "Token token=\"#{auth_token}\""}, as: :json
    assert_response :success
  end

  test 'unquoted authentication token' do
    get '/api/v1/ping', headers: {'Authorization': "Token token=#{auth_token}"}, as: :json
    assert_response :success
  end

  test 'missing authentication' do
    get '/api/v1/ping', as: :json
    assert_response :unauthorized
  end

  test 'invalid authentication header' do
    get '/api/v1/ping', headers: {'Authorization': "#{auth_token}"},as: :json
    assert_response :unauthorized
  end

  test 'invalid authentication token' do
    get '/api/v1/ping', headers: {'Authorization': "Token token=\"#{auth_token}xyz\""}, as: :json
    assert_response :unauthorized
  end

  # TODO: Thought this should fail, obviously Rails disagrees ...
  test 'different authentication type' do
    get '/api/v1/ping', headers: {'Authorization': "Bearer \"#{auth_token}\""}, as: :json
    assert_response :success
  end

end
