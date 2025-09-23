# config/routes/questionnaire.rb


scope path: "/questionnaire", module: "questionnaire", as: :questionnaire do
  resources :forms, only: %i[index show]
  resources :answers, only: %i[create show]
end
