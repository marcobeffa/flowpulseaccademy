class RenameContactsToLeads < ActiveRecord::Migration[8.0]
  def change
    rename_table :contacts, :leads
     end
end
