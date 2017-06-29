Rails.application.routes.draw do
  root to: 'top#index'

  resources :archives, only: %w(index show) do
    collection do
      get :map
      get :search_map
      get :graph
      get :draw
    end

    member do
      get :timeline
    end
  end

  get '*path', controller: 'application', action: 'render_not_found'
end
