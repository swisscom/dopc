class Api::V1::ApiController < ActionController::API

  include ActionController::MimeResponds

  wrap_parameters false

  before_action :accept_json, :json_content

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

end
