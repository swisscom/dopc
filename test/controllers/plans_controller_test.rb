require 'test_helper'

class PlansControllerTest < ActionDispatch::IntegrationTest

  test 'list plans' do
    get '/api/v1/plans', as: :json
    json = JSON.parse(@response.body)
    assert_response :success
  end

  test 'adding an invalid plan fails' do
    post '/api/v1/plans', params: {content: 'abc'}, as: :json
    json = JSON.parse(@response.body)
    assert_response :unprocessable_entity
  end

  test 'deleting a non-existent plan fails' do
    delete '/api/v1/plans/test', as: :json
    json = JSON.parse(@response.body)
    assert_response :not_found
  end

end
