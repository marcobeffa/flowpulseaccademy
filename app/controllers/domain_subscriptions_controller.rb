# app/controllers/domain_subscriptions_controller.rb
class DomainSubscriptionsController < ApplicationController
def create
    host = params[:host].to_s.downcase.presence ||
           DomainRegistry.match_base_domain_config(request.host)&.dig("host")
    Rails.logger.debug "host param: #{params[:host]}, resolved host: #{host}"
    return head :not_found unless host && DomainRegistry.domains.key?(host)
    Current.user.domain_subscriptions.find_or_create_by!(host: host)
    redirect_back fallback_location: root_path, notice: "Dominio attivato."
  end

  def destroy_by_host
    host = params[:host].to_s.downcase
    sub = Current.user.domain_subscriptions.find_by!(host: host)
    sub.destroy!
    redirect_back fallback_location: root_path, notice: "Dominio disattivato."
  end
end
