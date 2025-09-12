class Contact < ApplicationRecord
  enum :tipo_utente, {
    utente: 0,
    professionista_salute: 1,
    professionista_benessere: 2
  }
  before_validation :normalize_email

  validates :nome, :cognome, presence: true
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  validates :tipo_utente, presence: true
  validates :diventa_insegnante, inclusion: { in: [ true, false ] }

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
