class ScheduledEvent < ApplicationRecord
  belongs_to :contact
  belongs_to :training_course
end
