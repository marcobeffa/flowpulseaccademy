class PagesController < ApplicationController
  allow_unauthenticated_access

  layout "landing", only: %i[ home insegnanti ]
  def home
  end

  def index
  end

  def about
  end

  def contact
  end

  def insegnanti
  end
end
