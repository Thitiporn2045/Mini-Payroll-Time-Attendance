Rails.application.routes.draw do
  root "employees#index"

  resources :attendances, only: [ :index, :new, :create ]

  resources :employees do
    member do
      get :confirm_destroy
    end

    resources :attendances, only: [ :new, :create, :edit, :update ]
  end
end
