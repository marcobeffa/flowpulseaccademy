class PagesController < ApplicationController
  allow_unauthenticated_access

  layout "landing", only: %i[ home ]
  def home
  end

  def index
  end

  def about
  end

  def contact
  end
end
