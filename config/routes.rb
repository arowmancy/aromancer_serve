Rails.application.routes.draw do
  resource :session, only: [:create, :destroy]
  resource :users, only: [:create]
  resources :passwords, param: :token
  resources :legends, only: [:create, :index] do
    member do
      get :stream
    end
    resources :arena, only: [:create, :index] do
      collection do
        put :update
      end
    end
    resources :words, only: [] do
      member do
        get :possibilities
      end
    end
  end
  resources :players, only: [:update]
end
