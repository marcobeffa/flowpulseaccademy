namespace :admin do
    resources :users
    resources :sessions
    resources :contacts
    resources :training_courses
    resources :scheduled_events

    root to: "contacts#index"
end
