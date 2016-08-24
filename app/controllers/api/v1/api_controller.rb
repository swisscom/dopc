class Api::V1::ApiController < ActionController::API

  include ActionController::MimeResponds

  wrap_parameters false

  before_action :require_json

  def require_json
    respond_to :json
  end

end
