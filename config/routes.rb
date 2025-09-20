Rails.application.routes.draw do
  namespace :admin do
      resources :users
      resources :sessions
      resources :contacts
      resources :training_courses
      resources :scheduled_events

      root to: "contacts#index"
  end
  namespace :superadmin do
    # Index con tab
    get "indexcontact", to: "contacts#index",  as: :contacts
    # Update in-line del contatto (email/nome/cognome ecc.)
    patch "contacts/:id", to: "contacts#update", as: :contact
    # Assegna contatto a un User esistente
    post "contacts/:id/assign_user", to: "contacts#assign_user", as: :assign_user
    # Crea un User dal contatto e collega
    post "contacts/:id/create_user", to: "contacts#create_user", as: :create_user
  end
  resources :scheduled_events

  # Canoniche (SEO) su dominio academy.*

  get "categories/*taxonomy", to: "courses#index", as: :category

    resources :courses, only: [ :show, :index ], param: :slug do
      resources :lessons, only: [ :show ], param: :slug do
        resources :sheets, only: %i[show]
      end

      collection do
      get "admin_index"
    end
  end

  # get "/courses/igieneposturale", to: redirect("/courses/igiene_posturale")

  resources :training_courses
  get "dashboard/user"
  resources :contacts, only: %i[new create]
  scope module: :users do
    resource  :account,  only: [ :edit, :update ]     # /account
    resource  :change_passwords, only: [ :edit, :update ]     # /password/edit
  end
  resources :passwords, param: :token                                         # /users/password_resets/:token/edit
  resource :session
  get "pages/home"
  get "pages/index"
  get "pages/about"
  get "pages/contact"
  get "insegnanti", to: "pages#insegnanti"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pages#home"
end
