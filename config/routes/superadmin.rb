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
