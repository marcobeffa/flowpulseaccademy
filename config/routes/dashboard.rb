# config/routes.rb
namespace :dashboard do
  get :user, to: "user#show"
end
