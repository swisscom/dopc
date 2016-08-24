Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get '/ping', to: 'application#ping'
      resources :plans
    end
  end
end
