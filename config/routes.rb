Rails.application.routes.draw do
  root "employees#index"

  resources :attendances, only: [:index]

  resources :employees do
    resources :attendances, only: [:new, :create, :edit, :update]
  end
end
