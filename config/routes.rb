Rails.application.routes.draw do
  # Authentication routes
  post '/signup', to: 'users#create'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  get '/me', to: 'users#show'

  # Other routes
  resources :servers do
    member do
      post 'join'
      delete 'leave'
      patch 'transfer_ownership'
    end
    resources :messages, only: [:index]
  end

  mount ActionCable.server => '/cable'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  post 'rails/active_storage/direct_uploads', to: 'direct_uploads#create'
end
