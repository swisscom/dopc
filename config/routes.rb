Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get '/ping', to: 'application#ping'
      # Put will not work on :id, the name/id will be taken from the content
      put '/plans', to: 'plans#update_content'
      resources :plans do
        member do
          get 'versions'
        end
      end
      resources :executions
    end
  end
end
