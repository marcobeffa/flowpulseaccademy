# Final URLs:
# /onlinecourses                          → CatalogController#index
# /onlinecourses/categories/*taxonomy     → CatalogController#index
# /onlinecourses/:slug                    → CoursesController#show
# /onlinecourses/:course_slug/lezioni/:slug → LessonsController#show
scope path: "onlinecourses", as: :onlinecourses do
  get "/", to: "catalog#index", as: :catalog
  get "categories/*taxonomy", to: "catalog#index", as: :category

  # show su /onlinecourses/:slug
  resources :courses, only: [ :show ], param: :slug, path: "" do
    # show su /onlinecourses/:course_slug/lezioni/:slug
    resources :lessons, only: [ :show ], param: :slug, path: "lezioni"
  end
end



# <%= link_to "Catalogo", onlinecourses_catalog_path %>



# corso: <%= link_to "Igiene posturale", onlinecourses_course_path("igiene-posturale") %>


# Lezione <%= link_to "Lezione 1", onlinecourses_course_lesson_path("igiene-posturale", "lezione-1") %>

# Link assoluto con host: <%= link_to "Igiene posturale",   onlinecourses_course_url("igiene-posturale", host: "flowpulse.posturacorretta.org:3000") %>
