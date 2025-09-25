# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# db/seeds.rb
u = User.find_or_initialize_by(email_address: "mario@mario.it")
u.superadmin = true if u.respond_to?(:superadmin) # se hai la colonna
u.password = "123456"
u.password_confirmation = "123456"

# garantisci sempre il lead
if u.lead.blank?
  u.build_lead(
    nome: "Mario",
    cognome: "Rossi",
    email: "mario@mario.it",
    tipo_utente: 0
  )
else
  u.lead.email ||= u.email_address
end

u.save!

puts "[seed] user=#{u.email_address} superadmin=#{u.try(:superadmin)} lead_id=#{u.lead&.id}"
