require 'test_helper'

class PingTest < ActionDispatch::IntegrationTest

  setup do
    setup_auth
  end

  test 'ping returns pong' do
    get '/api/v1/ping', headers: auth_header, as: :json
    json = nil
    json = JSON.parse(@response.body)
    assert_equal 'pong', json['pong']
  end

end
