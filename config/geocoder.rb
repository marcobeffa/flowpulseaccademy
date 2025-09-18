# config/initializers/geocoder.rb
Geocoder.configure(
  timeout: 5,                 # secondi
  lookup: :nominatim,         # default gratuito (OpenStreetMap)
  units: :km,                 # unità di misura
  cache: Redis.new            # opzionale, per performance
)
