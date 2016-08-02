module Api
  module V1
    class ApplicationController < ActionController::API
      def ping
        render json: {text: 'pong'}
      end
    end
  end
end
