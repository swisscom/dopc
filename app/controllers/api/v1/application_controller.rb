module Api

  module V1

    class ApplicationController < ActionController::API

      include ActionController::MimeResponds

      before_action :require_json

      def require_json
        respond_to :json
      end

      def ping
        render json: {text: 'pong'}
      end

    end

  end

end
