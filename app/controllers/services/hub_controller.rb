# app/controllers/services/hub_controller.rb
# frozen_string_literal: true

class Services::HubController < ApplicationController
  def show
    dom = DomainRegistry.match_base_domain_config(request.host)
    head :not_found and return unless dom

    sub, base = DomainRegistry.split_host(request.host)
    head :not_found and return unless sub && base == dom["host"]

    @domain      = dom
    @domain_key  = dom["host"].to_s.split(".").first
    @active_keys = Array(dom["active_services"]).map(&:to_s)

    # roots plausibili
    yml_roots = @active_keys.map { |k| DomainRegistry.service(k)&.dig("yml_root") }.compact
    yml_roots += [ "config/courses", "config/yml_data", "config/courses/data_yml" ]
    roots = yml_roots.uniq.map { |p| Rails.root.join(p).to_s }

   index = HubIndex.new(domain_key: @domain_key, active_keys: @active_keys, roots: roots)
    payload = index.fetch

    @folders = payload[:folders]
    @cards   = payload[:cards]
    @scanned = payload[:scanned]
  end
end
