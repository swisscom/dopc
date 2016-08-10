class ApplicationController < ActionController::API

  include ActionController::MimeResponds

  before_action :require_json

  def require_json
    respond_to :json
  end

end
