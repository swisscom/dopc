Rails.application.routes.draw do
  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      get '/ping', to: 'application#ping'
    end
  end
end
