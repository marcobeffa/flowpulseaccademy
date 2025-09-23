# config/routes/generaimpresa.rb
namespace :generaimpresa do
  resources :lists do
    member do
      get  :order
      patch :reorder
    end
  end
end
