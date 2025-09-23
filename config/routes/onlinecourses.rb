# config/routes/onlinecourses.rb
# final URL example: https://flowpulse.posturacorretta.org/onlinecourses/...


scope path: "/onlinecourses", module: "onlinecourses", as: :onlinecourses do
  # Example routes (adapt to your controllers)
  get "/", to: "catalog#index", as: :catalog
  get "/categories/*taxonomy", to: "catalog#index", as: :category


  resources :courses, only: %i[index show], param: :slug, path: "/corsi" do
    resources :lessons, only: %i[show], param: :slug, path: "/lezioni"
  end
end
