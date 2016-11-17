class Api::V1::ApiController < ActionController::API

  include ActionController::MimeResponds
  include ActionController::HttpAuthentication::Token::ControllerMethods 

  wrap_parameters false

  before_action :accept_json, :json_content, :authenticate

  private

  def accept_json
    respond_to :json
  rescue ActionController::UnknownFormat
    render json: {error: 'Client does not accept JSON format'}, status: :not_acceptable
  end

  def json_content
    if request.content_type && (request.content_type != 'application/json')
      render json: {error: 'Client set content type to non-JSON format'}, status: :unsupported_media_type
    end
  end

  def authenticate
    authenticate_or_request_with_http_token do |token, options|
      token == get_auth_token
    end
  end

  def get_auth_token
    APP_CONFIG['auth_token']
  end

end
