# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :domain   # 👈 aggiunto :domain
  delegate :user, to: :session, allow_nil: true

  # opzionale: azzera il domain a ogni richiesta/reset, senza toccare session
  resets { self.domain = nil }
end
