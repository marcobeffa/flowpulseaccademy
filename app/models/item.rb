# app/models/item.rb
class Item < ApplicationRecord
  belongs_to :list
  has_ancestry orphan_strategy: :destroy

  validates :title, presence: true
end
