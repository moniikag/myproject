class TodoItem < ActiveRecord::Base

  belongs_to :todo_list

  validates :content, presence: true

  scope :complete, -> { where("completed_at is not null") }
  scope :incomplete, -> { where(completed_at: nil) }

  acts_as_taggable

  def urgent?
    self.deadline < 24.hours.from_now if self.deadline.present?
  end

end
