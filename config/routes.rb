Rails.application.routes.draw do
  root "employees#index"

  resources :employees, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    resources :attendances, only: [:new, :create, :edit, :update]
  end
end