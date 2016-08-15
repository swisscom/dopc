require 'test_helper'

class ApplicationControllerTest < ActionDispatch::IntegrationTest

  test 'ping returns pong' do
    get '/api/v1/ping', as: :json
    json = nil
    json = JSON.parse(@response.body)
    assert_equal 'pong', json['text']
  end

end
