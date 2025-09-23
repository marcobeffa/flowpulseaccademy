class ReorderList
  def self.call(list, nodes, delete_missing: false)
    new(list, nodes, delete_missing: delete_missing).call
  end

  def initialize(list, nodes, delete_missing:)
    @list = list
    @nodes = Array(nodes)
    @delete_missing = delete_missing
    @seen_ids = []
  end

  def call
    ActiveRecord::Base.transaction do
      upsert_level(@nodes, parent: nil)
      @list.items.where.not(id: @seen_ids).delete_all if @delete_missing
    end
  end

  private

  def upsert_level(arr, parent:)
    arr.each_with_index do |node, idx|
      item = find_or_build_item(node, parent:)
      item.title    = node[:title].to_s
      item.parent   = parent
      item.position = idx
      item.save!
      @seen_ids << item.id
      upsert_level(Array(node[:children]), parent: item)
    end
  end

  def find_or_build_item(node, parent:)
    if node[:id].present?
      @list.items.find(node[:id])
    else
      @list.items.build(parent: parent)
    end
  end
end
