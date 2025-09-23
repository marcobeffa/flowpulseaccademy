# config/routes/generaimpresa.rb
namespace :generaimpresa do
  resources :lists, only: [ :index, :show ] do
    member do
      get  :order   # /generaimpresa/lists/:id/order  (HTML/JSON)
      post :order  # /generaimpresa/lists/:id/order  (salvataggio)
    end
  end
end
