perfetto, impostiamo dashboard/user in modo che:

capisca da URL (host + path) quale brand e quale service stai guardando;

mostri i contenuti presi da catalog_items filtrati per brand e, se presente, per service;

costruisca i link corretti usando i tuoi helper.

Di seguito i pezzi pronti.

1) Context parser (host → brand + service + slug)

Crea un parser centralizzato che deduce il brand (base host), l’eventuale subdomain di servizio (es. flowpulse) e l’eventuale service key dal path (/onlinecourses/...).

# app/services/request_context.rb
# frozen_string_literal: true

module RequestContext
  module_function

  # Ritorna un Hash con:
  # :base_host, :domain (hash dal registry), :subdomain, :service_key, :slug, :segments
  def parse(host:, path:)
    dom = DomainRegistry.match_base_domain_config(host)
    return empty unless dom

    base_host = dom["host"]
    sub = subdomain_part(host, base_host) # "flowpulse" oppure "www"/nil

    # Se il sottodominio corrisponde a un subdomain di servizio, proviamo a leggere il service dal path
    service_key = nil
    segments = split_segments(path)
    if sub && DomainRegistry.service_subdomains.include?(sub)
      # Il path è in forma: /<service_key>(/<slug>...)
      key = segments[0].to_s
      active = Array(dom["active_services"]).map!(&:to_s)
      service_key = key if active.include?(key) && DomainRegistry.services.key?(key)
    end

    slug = segments[1]

    {
      base_host: base_host,
      domain: dom,
      subdomain: sub,
      service_key: service_key,
      slug: slug,
      segments: segments
    }
  end

  def empty = { base_host: nil, domain: nil, subdomain: nil, service_key: nil, slug: nil, segments: [] }

  # --- helpers ---
  def subdomain_part(host, base_host)
    return nil unless host&.end_with?(".#{base_host}")
    sub = host.delete_suffix(".#{base_host}")
    # scarta sottodomini multipli tipo "www" o "api.v1" (tieni solo la prima label)
    sub&.include?(".") ? sub.split(".").last : sub
  end

  def split_segments(path)
    path.to_s.split("/").reject(&:blank?)
  end
end


Aggiungi due utility al DomainRegistry (nel tuo initializer), così:

# config/initializers/domain_registry.rb (in coda, metodi helper)
module DomainRegistry
  class << self
    # insieme dei subdomain dei servizi (es. ["flowpulse"])
    def service_subdomains
      @service_subdomains ||= services.values.map { |s| s["subdomain"] }.compact.uniq
    end

    # true se key è una service key valida
    def service_key?(key) = services.key?(key.to_s)
  end
end

2) Controller dashboard

Usiamo Dashboard::UserController#show (manteniamo la tua rotta “dashboard/user”). Il controller:

ricava il context (brand, service) dall’URL,

prende i brand sottoscritti dall’utente,

filtra i catalog_items per brand e (se c’è) per service.

# app/controllers/dashboard/user_controller.rb
module Dashboard
  class UserController < ApplicationController
    before_action :authenticate_user!

    def show
      @ctx = RequestContext.parse(host: request.host, path: request.path)

      # Brand (host) sottoscritti dall’utente
      subs_hosts = current_user.brand_subscriptions.pluck(:host)

      # Se sto visitando un host di servizio (flowpulse.<brand>), forza il brand corrente in testa
      current_host = @ctx[:base_host]
      hosts = (current_host.present? ? [current_host] : []) | subs_hosts

      # servizi attivi per ciascun brand
      @active_services = {}
      hosts.each do |h|
        dom = DomainRegistry.domains[h] or next
        @active_services[h] = Array(dom["active_services"]).map!(&:to_s)
      end

      # Query indice
      scope = CatalogItem.where(host: hosts)
      scope = scope.where(service_key: @ctx[:service_key]) if @ctx[:service_key].present?
      @items = scope.order(Arel.sql("COALESCE(published_at, created_at) DESC")).limit(48)

      # Per sidebar/menu
      @brands = hosts.map { |h| DomainRegistry.domains[h] }.compact.index_by { |d| d["host"] }
    end
  end
end


Rotte (se non le hai già):

# config/routes.rb
namespace :dashboard do
  get :user, to: "user#show"
end

3) View di dashboard (scheletro)

Una view minimale che usa @ctx, i brand attivi e l’indice @items. I link si costruiscono coi tuoi helper ServicesHelper.

<!-- app/views/dashboard/user/show.html.erb -->
<div class="max-w-7xl mx-auto px-4 py-8">
  <h1 class="text-2xl font-semibold mb-4">La tua dashboard</h1>

  <% if @brands.blank? %>
    <p class="text-gray-600">Non hai brand attivati. Vai alla pagina Flowpulse per attivarne uno.</p>
  <% else %>
    <%# CONTEXT: se sono su flowpulse.<brand> e il path include /<service_key>, evidenzio il servizio %>
    <% if @ctx[:service_key].present? %>
      <div class="mb-4 text-sm text-gray-600">
        Contesto: <strong><%= @ctx[:base_host] %></strong> — servizio
        <span class="inline-block px-2 py-0.5 border rounded"><%= @ctx[:service_key] %></span>
      </div>
    <% end %>

    <% @brands.each do |host, dom| %>
      <div class="mb-8 border rounded-xl p-4">
        <div class="flex items-center justify-between mb-2">
          <h2 class="text-xl font-semibold"><%= dom.dig("seo","title") || host %></h2>
          <div class="text-sm text-gray-500"><%= dom["description"] %></div>
        </div>

        <% active = @active_services[host] || [] %>
        <div class="flex flex-wrap gap-2 mb-4">
          <% active.each do |key| %>
            <% url = service_url_for(key, host: host) %>
            <a href="<%= url %>" class="px-3 py-1 text-sm border rounded hover:bg-gray-50">
              <%= DomainRegistry.service(key).try { |s| s["title"] } || key.humanize %>
            </a>
          <% end %>
        </div>

        <% items = @items.select { |ci| ci.host == host } %>
        <% if items.any? %>
          <div class="grid gap-3 md:grid-cols-2 lg:grid-cols-3">
            <% items.each do |ci| %>
              <div class="border rounded-lg p-3">
                <div class="text-xs uppercase text-gray-500 mb-1"><%= ci.service_key %></div>
                <div class="font-medium mb-1"><%= ci.title %></div>
                <% if ci.published_at %>
                  <div class="text-xs text-gray-400 mb-2"><%= l(ci.published_at.to_date) %></div>
                <% end %>
                <%# URL pubblico: https://<sub>.<host>/<service_key>/<slug> %>
                <% href = service_url_for(ci.service_key, host: ci.host, path: ci.slug) %>
                <a href="<%= href %>" class="inline-block text-sm px-3 py-1 border rounded-md hover:bg-gray-50">Apri</a>
              </div>
            <% end %>
          </div>
        <% else %>
          <div class="text-sm text-gray-500">Nessun contenuto recente.</div>
        <% end %>
      </div>
    <% end %>
  <% end %>
</div>


Nota: service_url_for(ci.service_key, host: ci.host, path: ci.slug) usa l’helper che hai sistemato. Se preferisci l’URL completo con /service_key/slug, usa path: "#{ci.service_key}/#{ci.slug}".

4) Sidebar/partials (opzionale)

Se hai una sidebar condivisa, puoi mostrare i servizi del brand corrente usando @ctx:

<!-- app/views/shared/dashboard/_sidebar_content.html.erb -->
<% current_host = @ctx&.dig(:base_host) %>
<% if current_host %>
  <% active = @active_services[current_host] || [] %>
  <ul class="space-y-1">
    <% active.each do |key| %>
      <li>
        <%= link_to (DomainRegistry.service(key).try { |s| s["title"] } || key.humanize),
                    service_url_for(key, host: current_host),
                    class: "block px-3 py-1 rounded hover:bg-gray-50" %>
      </li>
    <% end %>
  </ul>
<% end %>

5) Come “ricava il service” dall’URL?

Dalla host: se l’host è flowpulse.posturacorretta.org, il parser sa che subdomain = "flowpulse" e dunque sei su un host di servizio (hub).

Dal path: "/onlinecourses/igiene-posturale" → service_key = "onlinecourses", slug = "igiene-posturale".

Se il path è solo /, è la hub del sottodominio (services/hub#show) e service_key=nil.

Questo è esattamente quello che fa RequestContext.parse.

6) Query catalog_items

Filtriamo per i brand dell’utente.

Se il context deduce un service_key, filtriamo anche per quello (così se l’utente è su flowpulse.<brand>/onlinecourses/... la dashboard mostra subito gli item di quel servizio).