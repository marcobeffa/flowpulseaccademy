# frozen_string_literal: true

module Domains
  class FlowpulseController < ApplicationController
    def home
      @domains  = DomainRegistry.domains.values.sort_by { |d| d["host"] }
      @services = DomainRegistry.services.values.sort_by { |s| s["key"] }
      @superadmin = current_user&.respond_to?(:superadmin?) && current_user.superadmin?
      @user_hosts = current_user ? current_user.domain_subscriptions.pluck(:host) : []
      @proto = request.protocol
      @port  = request.port && ![ 80, 443 ].include?(request.port) ? ":#{request.port}" : ""
    end
  end
end
