Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get '/ping', to: 'application#ping'
      # Put will not work on :id, the name/id will be taken from the content
      put '/plans', to: 'plans#update_content'
      resources :plans do
        member do
          get 'versions'
          put 'reset'
          get 'state'
        end
      end
      delete '/executions', to: 'executions#destroy_multiple'
      resources :executions do
        member do
          get 'log'
        end
      end
    end
  end
end
