scope path: "/blog", module: "blog", as: :blog do
  resources :posts, only: %i[index show], param: :slug
end
