# config/routes.rb
Rails.application.routes.draw do
  DomainRegistry.load!

  # helper per includere file di rotte spezzati
  def draw(name)
    path = Rails.root.join("config/routes/#{name}.rb")
    instance_eval(File.read(path), path.to_s, 1)
  end

  # --- SERVIZI: montati solo sui subdomain abilitati ---
  %i[onlinecourses teaching questionnaire blog].each do |svc_key|
    constraints DomainRoutes.service_constraint(svc_key) do
      draw svc_key  # es.: config/routes/onlinecourses.rb
    end
  end

  # --- BRAND ROOT + pagine brand + redirect /:key -> subdomain ---
  DomainRegistry.each_domain do |dom|
    # Root per ciascun subdomain attivo: https://<sub>.<domain>/
    Array(dom["active_services"])
      .map  { |k| DomainRegistry.service(k) }
      .compact
      .map  { |svc| svc["subdomain"] }
      .uniq
      .each do |sub|
        host = "#{sub}.#{dom['host']}"
        constraints host: /\A#{Regexp.escape(host)}\z/ do
          root to: "services/hub#show", as: "root_#{host.parameterize}"
        end
      end

    # Root per il BRAND (dominio nudo + alias)
    hosts = DomainRegistry.all_hosts_for_domain(dom) # [host, alias1, ...]
    constraints DomainRoutes.domain_constraint_for_hosts(hosts) do
      # Landing brand
      root to: DomainRoutes.brand_controller_for(dom, action: "home"),
           as: "brand_root_#{dom['host'].tr('.', '_')}"
      # Alias comodo
      get "/home", to: DomainRoutes.brand_controller_for(dom, action: "home"),
                   as: "brand_home_#{dom['host'].tr('.', '_')}"

      # Pagine standard del brand
      get "/about",   to: DomainRoutes.brand_controller_for(dom, action: "about")
      get "/contact", to: DomainRoutes.brand_controller_for(dom, action: "contact")
      get "/privacy", to: DomainRoutes.brand_controller_for(dom, action: "privacy")
      get "/terms",   to: DomainRoutes.brand_controller_for(dom, action: "terms")

      # Pagine EXTRA per-brand (se usi DomainRoutes.brand_pages)
      if DomainRoutes.respond_to?(:brand_pages)
        extra = (DomainRoutes.brand_pages(dom) - %w[home about contact privacy terms])
        unless extra.empty?
          get "/:page",
              to: DomainRoutes.brand_controller_for(dom, action: "page"),
              constraints: { page: /\A(?:#{extra.join("|")})\z/ }
        end
      end

      # Redirect 301: dominio-nudo/:key → subdomain.dominio/:key
      Array(dom["active_services"]).each do |svc_key|
        svc = DomainRegistry.service(svc_key)
        next unless svc

        get "/#{svc_key}/*rest", to: redirect(status: 301) { |p, req|
          "#{req.protocol}#{svc['subdomain']}.#{dom['host']}/#{svc_key}/#{p[:rest]}"
        }
        get "/#{svc_key}", to: redirect(status: 301) { |_p, req|
          "#{req.protocol}#{svc['subdomain']}.#{dom['host']}/#{svc_key}"
        }
      end
    end
  end

  # --- Aree generiche ---
  resources :domain_subscriptions, only: [ :create ]

  post "domains/subscribe", to: "domain_subscriptions#create", as: :subscribe_domain
  delete "domains/:host/unsubscribe", to: "domain_subscriptions#destroy", as: :unsubscribe_domain
  draw :dashboard
  draw :superadmin
  draw :admin
  draw :generaimpresa
  draw :impegno

  resources :domains, only: %i[index show]

  scope module: :users do
    resource :account,          only: %i[edit update]
    resource :change_passwords, only: %i[edit update]
  end

  resources :leads,  only: %i[new create]
  resources :passwords, param: :token
  resource  :session

  get "dashboard/user"
  get "pages/index"
  get "pages/about"
  get "pages/contact"
  get "insegnanti", to: "pages#insegnanti"

  get "up" => "rails/health#show", as: :rails_health_check

  # fallback per host non gestiti
  root "pages#home"
  get "/home", to: "pages#home", as: :pages_home
 end
