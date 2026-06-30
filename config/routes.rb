Rails.application.routes.draw do
  resources :legends, only: [:create, :update, :show, :index] do
    resources :arena, only: [:create, :index] do
      collection do
        put :update
      end
    end
    resources :word, only: [] do
      member do
        get :possibilities
      end
    end
  end
  resources :players
end
