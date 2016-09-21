require 'test_helper'

class PingTest < ActionDispatch::IntegrationTest

  test 'ping returns pong' do
    get '/api/v1/ping', as: :json
    json = nil
    json = JSON.parse(@response.body)
    assert_equal 'pong', json['pong']
  end

end