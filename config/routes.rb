# config/routes.rb
Rails.application.routes.draw do
  # Assicurati che il registry sia caricato quando si disegnano le rotte

  DomainRegistry.load!

  # Helper per includere file di rotte spezzati
  def draw(name)
    path = Rails.root.join("config/routes/#{name}.rb")
    instance_eval(File.read(path), path.to_s, 1)
  end

  # ROOT per ogni dominio (e alias) + redirect 301 dal dominio base ai sottodomini di servizio
  DomainRegistry.each_domain do |dom|
    subdomains = Array(dom["active_services"])
                 .map { |k| DomainRegistry.service(k) }
                 .compact
                 .map { |svc| svc["subdomain"] }
                 .uniq

    subdomains.each do |sub|
      host = "#{sub}.#{dom['host']}"
      constraints host: /\A#{Regexp.escape(host)}\z/ do
        # root del sottodominio → Services::HubController#show
        root to: "services/hub#show", as: "service_hub_#{host.parameterize}"
      end
    end
    hosts = DomainRegistry.all_hosts_for_domain(dom) # => [host, alias1, alias2, ...]
    constraints DomainRoutes.domain_constraint_for_hosts(hosts) do
      # landing del dominio: sempre "/" su quel host
      root to: "domains/home#show", as: "root_#{dom['host'].parameterize}"

      # Redirect 301: /<service>(/*rest) -> https://<svc_sub>.<domain>/<service>(/*rest)
      Array(dom["active_services"]).each do |svc_key|
        svc = DomainRegistry.service(svc_key)
        next unless svc

        get "/#{svc_key}/*rest", to: redirect(status: 301) { |params, _req|
          "https://#{svc['subdomain']}.#{dom['host']}/#{svc_key}/#{params[:rest]}"
        }
        get "/#{svc_key}", to: redirect(status: 301) { |_params, _req|
          "https://#{svc['subdomain']}.#{dom['host']}/#{svc_key}"
        }
      end
    end
  end

  # SERVICE ROUTES — montate SOLO sugli host permessi (subdomain + base domain)
  # constraints DomainRoutes.service_constraint(:onlinecourses) { draw :onlinecourses }
  # constraints DomainRoutes.service_constraint(:teaching)      { draw :teaching }
  # constraints DomainRoutes.service_constraint(:questionnaire) { draw :questionnaire }
  # constraints DomainRoutes.service_constraint(:blog)          { draw :blog }

  constraints DomainRoutes.service_constraint(:onlinecourses) do
    draw :onlinecourses
  end
  constraints DomainRoutes.service_constraint(:teaching) do
    draw :teaching
  end
  constraints DomainRoutes.service_constraint(:questionnaire) do
    draw :questionnaire
  end
  constraints DomainRoutes.service_constraint(:blog) do
    draw :blog
  end
  # --- Altre aree dell'app (non legate ai domini/servizi) ---
  draw :superadmin
  draw :admin
  draw :generaimpresa
  draw :impegno

  resources :domains,   only: %i[index show]
  get "dashboard/user"
  resources :contacts,  only: %i[new create]

  scope module: :users do
    resource :account,          only: %i[edit update]       # /account
    resource :change_passwords, only: %i[edit update]       # /password/edit
  end

  resources :passwords, param: :token                       # /passwords/:token
  resource  :session

  get "pages/home"
  get "pages/index"
  get "pages/about"
  get "pages/contact"
  get "insegnanti", to: "pages#insegnanti"

  # Healthcheck
  get "up" => "rails/health#show", as: :rails_health_check

  # (opzionale) root di fallback per host NON gestiti da DomainRegistry:
  # root "pages#home"
  root "pages#home"
  get "/home", to: "pages#home", as: :pages_home
end
