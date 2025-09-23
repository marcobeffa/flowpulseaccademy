# config/initializers/hub_cache.rb
# frozen_string_literal: true

module HubCache
  KEY = "hub_cache_version"

  module_function

  def version
    Rails.cache.fetch(KEY) { 1 }
  end

  def bump!
    Rails.cache.write(KEY, version.to_i + 1)
  end
end
# In production, quando carichi/aggiorni YML senza redeploy, chiama HubCache.bump! per invalidare tutti gli index in cache.
