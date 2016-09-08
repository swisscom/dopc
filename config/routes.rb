Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get '/ping', to: 'application#ping'
      resources :plans do
        member do
          get 'check'
          post 'run'
        end
      end
      resources :executions
    end
  end
end
