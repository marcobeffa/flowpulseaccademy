# config/routes/generaimpresa.rb
namespace :generaimpresa do
  resources :lists do
    member do
      get  :order
      patch :order
    end
  end
end
