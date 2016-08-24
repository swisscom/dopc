class Api::V1::ApplicationController < Api::V1::ApiController

  def ping
    render json: {pong: 'pong'}
  end

end
