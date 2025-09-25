class ScheduledEvent < ApplicationRecord
  belongs_to :lead
  belongs_to :training_course
end
