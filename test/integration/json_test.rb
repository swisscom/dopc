require 'test_helper'

class JsonTest < ActionDispatch::IntegrationTest

  test 'accept json' do
    get '/api/v1/ping', headers: {'Accept' => 'application/json'}
    assert_response :success
    assert_equal @response.content_type, 'application/json'
  end

  test 'accept any' do
    get '/api/v1/ping', headers: {'Accept' => '*/*'}
    assert_response :success
    assert_equal @response.content_type, 'application/json'
  end

  test 'do not accept text' do
    assert_raises ActionController::UnknownFormat do
      get '/api/v1/ping', headers: {'Accept' => 'text/plain'}
    end
    # can not further check, since response is nil after asserting exception
    #assert_response :not_acceptable
    #assert_equal @response.content_type, 'application/json'
  end

end
