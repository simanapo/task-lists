Rails.application.routes.draw do
  devise_for :users, controllers: { :omniauth_callbacks => "omniauth_callbacks" }
  root 'tasks#index'
  get 'tasks/show'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # タスク
  resources :tasks, only: [:index, :create, :update, :destroy] do
    collection do
      post :confirm
    end
    member do
      patch :sort
      patch :update_confirm
    end
  end
end
