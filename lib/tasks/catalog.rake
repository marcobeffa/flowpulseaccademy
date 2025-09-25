# lib/tasks/catalog.rake
namespace :catalog do
  desc "Indicizza TUTTO (YML + DB full sync)"
  task sync: :environment do
    Catalog::Indexer.run!
    puts "Catalog indicizzato."
  end

  desc "Indicizza solo un brand"
  task :sync_brand, [ :host ] => :environment do |_, args|
    host = args[:host] or abort "usa: rake catalog:sync_brand[posturacorretta.org]"
    Catalog::Indexer.run!(hosts: [ host ])
    puts "Catalog indicizzato per #{host}."
  end
end
