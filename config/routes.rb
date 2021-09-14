Rails.application.routes.draw do
  devise_for :accounts
  root 'books#index'

  resources :books
  resources :accounts, only: [:show]
end
