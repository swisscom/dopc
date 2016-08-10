module Api
  module V1
    class ApplicationController < ::ApplicationController

      def ping
        render json: {text: 'pong'}
      end

    end
  end
end
