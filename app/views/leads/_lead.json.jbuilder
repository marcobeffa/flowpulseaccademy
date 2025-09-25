json.extract! lead, :id, :nome, :cognome, :email, :diventa_insegnante, :tipo_utente, :created_at, :updated_at
json.url lead_url(lead, format: :json)
