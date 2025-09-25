# config/routes/brands.rb
if Rails.env.development?
  namespace :domains do
    %w[flowpulse igieneposturale posturacorretta stopaldolore benessereintegrato].each do |brand|
      get "#{brand}/home", to: "#{brand}#home", as: "#{brand}_home_dev"
    end
  end
end
