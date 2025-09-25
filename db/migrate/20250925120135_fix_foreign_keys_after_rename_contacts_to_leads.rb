# db/migrate/20250925_fix_foreign_keys_after_rename_contacts_to_leads.rb
class FixForeignKeysAfterRenameContactsToLeads < ActiveRecord::Migration[8.0]
  def up
    # -- training_courses.contact_id -> lead_id --------------------------------
    if foreign_key_exists?(:training_courses, :contacts)
      remove_foreign_key :training_courses, :contacts
    end

    if column_exists?(:training_courses, :contact_id)
      rename_column :training_courses, :contact_id, :lead_id
    end

    if index_exists?(:training_courses, :contact_id)
      safe_rename_index(:training_courses,
                        :index_training_courses_on_contact_id,
                        :index_training_courses_on_lead_id)
    end

    unless foreign_key_exists?(:training_courses, :leads, column: :lead_id)
      add_foreign_key :training_courses, :leads, column: :lead_id
    end

    # -- scheduled_events.contact_id -> lead_id --------------------------------
    if foreign_key_exists?(:scheduled_events, :contacts)
      remove_foreign_key :scheduled_events, :contacts
    end

    if column_exists?(:scheduled_events, :contact_id)
      rename_column :scheduled_events, :contact_id, :lead_id
    end

    if index_exists?(:scheduled_events, :contact_id)
      safe_rename_index(:scheduled_events,
                        :index_scheduled_events_on_contact_id,
                        :index_scheduled_events_on_lead_id)
    end

    unless foreign_key_exists?(:scheduled_events, :leads, column: :lead_id)
      add_foreign_key :scheduled_events, :leads, column: :lead_id
    end

    # -- leads.responsable_contact_id -> leads.responsable_lead_id -------------
    if foreign_key_exists?(:leads, column: :responsable_contact_id)
      remove_foreign_key :leads, column: :responsable_contact_id
    end

    if column_exists?(:leads, :responsable_contact_id)
      rename_column :leads, :responsable_contact_id, :responsable_lead_id
    end

    if index_exists?(:leads, :responsable_contact_id)
      safe_rename_index(:leads,
                        :index_leads_on_responsable_contact_id,
                        :index_leads_on_responsable_lead_id)
    end

    unless foreign_key_exists?(:leads, :leads, column: :responsable_lead_id)
      add_foreign_key :leads, :leads, column: :responsable_lead_id
    end
  end

  def down
    # -- revert leads.responsable_lead_id -> responsable_contact_id ------------
    if foreign_key_exists?(:leads, :leads, column: :responsable_lead_id)
      remove_foreign_key :leads, column: :responsable_lead_id
    end

    if index_exists?(:leads, :responsable_lead_id)
      safe_rename_index(:leads,
                        :index_leads_on_responsable_lead_id,
                        :index_leads_on_responsable_contact_id)
    end

    if column_exists?(:leads, :responsable_lead_id)
      rename_column :leads, :responsable_lead_id, :responsable_contact_id
    end

    unless foreign_key_exists?(:leads, column: :responsable_contact_id)
      add_foreign_key :leads, :leads, column: :responsable_contact_id
    end

    # -- revert scheduled_events.lead_id -> contact_id -------------------------
    if foreign_key_exists?(:scheduled_events, :leads, column: :lead_id)
      remove_foreign_key :scheduled_events, column: :lead_id
    end

    if index_exists?(:scheduled_events, :lead_id)
      safe_rename_index(:scheduled_events,
                        :index_scheduled_events_on_lead_id,
                        :index_scheduled_events_on_contact_id)
    end

    if column_exists?(:scheduled_events, :lead_id)
      rename_column :scheduled_events, :lead_id, :contact_id
    end

    unless foreign_key_exists?(:scheduled_events, :contacts, column: :contact_id)
      add_foreign_key :scheduled_events, :contacts, column: :contact_id
    end

    # -- revert training_courses.lead_id -> contact_id -------------------------
    if foreign_key_exists?(:training_courses, :leads, column: :lead_id)
      remove_foreign_key :training_courses, column: :lead_id
    end

    if index_exists?(:training_courses, :lead_id)
      safe_rename_index(:training_courses,
                        :index_training_courses_on_lead_id,
                        :index_training_courses_on_contact_id)
    end

    if column_exists?(:training_courses, :lead_id)
      rename_column :training_courses, :lead_id, :contact_id
    end

    unless foreign_key_exists?(:training_courses, :contacts, column: :contact_id)
      add_foreign_key :training_courses, :contacts, column: :contact_id
    end
  end

  private

  # Rinominare un indice può fallire se il nome non combacia (dipende da come l’ha creato Rails).
  # Con questo helper tentiamo sia per symbol che per string e ignoriamo errori non critici.
  def safe_rename_index(table, old_name, new_name)
    rename_index(table, old_name, new_name)
  rescue
    begin
      rename_index(table, old_name.to_s, new_name.to_s)
    rescue
      # come fallback: ricrea l'indice se esiste sul vecchio campo
      # (qui potresti anche drop+create con add_index)
    end
  end
end
