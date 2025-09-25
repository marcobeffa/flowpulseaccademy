namespace :superadmin do
  post "catalog/sync",        to: "catalog#sync",       as: :catalog_sync
  post "catalog/:host/sync",  to: "catalog#sync_brand", as: :catalog_sync_brand

  # Index con tab
  get "indexlead", to: "leads#index",  as: :leads
  # Update in-line del contatto (email/nome/cognome ecc.)
  patch "leads/:id", to: "leads#update", as: :lead
  # Assegna contatto a un User esistente
  post "leads/:id/assign_user", to: "leads#assign_user", as: :assign_user
  # Crea un User dal contatto e collega
  post "leads/:id/create_user", to: "leads#create_user", as: :create_user
end
