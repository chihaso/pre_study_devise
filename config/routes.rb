Rails.application.routes.draw do
  root 'books#index'
  devise_for :accounts, controllers: {
    confirmations: 'accounts/confirmations',
    # omniauth_callbacks: 'accounts/omniauth_callbacks',
    passwords: 'accounts/passwords',
    registrations: 'accounts/registrations',
    sessions: 'accounts/sessions',
    unlocks: 'accounts/unlocks',
  }

  resources :books
  resources :accounts, only: [:show]
end
