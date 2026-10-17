Rails.application.routes.draw do
  mount ActionCable.server => :"/broadcast".to_s
  root "application#rules"
  resource :session, only: [:create, :destroy]
  resource :users, only: [:create]
  resources :passwords, param: :token
  resources :players, only: [:update]
  resources :legends, only: [:create, :index] do

    member do
      get :stream
    end

    collection do
      get :find
    end

    resources :arena, only: [:index, :update]
    resources :words, only: [] do
      member do
        get :possibilities
      end
    end
  end
end
