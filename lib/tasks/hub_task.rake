# lib/tasks/hub_cache.rake
namespace :hub do
  desc "Bump Hub cache version (invalidates cached hub indices)"
  task bump: :environment do
    old = HubCache.version
    HubCache.bump!
    puts "Hub cache bumped: #{old} -> #{HubCache.version}"
  end
end

namespace :domain do
  desc "Reload DomainRegistry from config/domains.yml"
  task reload: :environment do
    DomainRegistry.load!(force: true)
    puts "DomainRegistry reloaded."
  end
end
# bin/rails domain:reload
# bin/rails hub:bump
