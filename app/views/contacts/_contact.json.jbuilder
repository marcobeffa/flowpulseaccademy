json.extract! contact, :id, :nome, :cognome, :email, :diventa_insegnante, :tipo_utente, :created_at, :updated_at
json.url contact_url(contact, format: :json)
