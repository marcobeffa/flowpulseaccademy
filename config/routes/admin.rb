namespace :admin do
    resources :users
    resources :sessions
    resources :leads
    resources :catalog_items
    resources :training_courses
    resources :catalog_items


    root to: "leads#index"
end
