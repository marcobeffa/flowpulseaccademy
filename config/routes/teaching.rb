# config/routes/teaching.rb
# https://flowpulse.<domain>/teaching/...


scope path: "/teaching", module: "teaching", as: :teaching do
  resources :training_courses, param: :slug
  resources :scheduled_events
end
