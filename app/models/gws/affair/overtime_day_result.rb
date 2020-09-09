class Gws::Affair::OvertimeDayResult
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Affair::FileTarget
  include Gws::Affair::OvertimeDayResult::UserAggregate
  include Gws::Affair::OvertimeDayResult::CapitalAggregate

  belongs_to :file, class_name: "Gws::Affair::OvertimeFile"

  field :date, type: DateTime
  field :date_year, type: Integer
  field :date_month, type: Integer

  field :start_at, type: DateTime
  field :end_at, type: DateTime

  belongs_to :capital, class_name: "Gws::Affair::Capital"
  field :is_holiday, type: Boolean
  field :overtime_minute, type: Integer
  field :duty_day_time_minute, type: Integer
  field :duty_night_time_minute, type: Integer
  field :leave_day_time_minute, type: Integer
  field :leave_night_time_minute, type: Integer
  field :week_in_compensatory_minute, type: Integer
  field :week_out_compensatory_minute, type: Integer
  field :break_time_minute, type: Integer
  field :duty_day_in_work_time_minute, type: Integer

  validates :file_id, presence: true
  validates :date, presence: true, uniqueness: { scope: [:site_id, :user_id, :file_id] }
  validates :date_year, presence: true
  validates :date_month, presence: true

  validates :capital_id, presence: true
  validates :is_holiday, presence: true
  validates :overtime_minute, presence: true
  validates :duty_day_time_minute, presence: true
  validates :duty_night_time_minute, presence: true
  validates :leave_day_time_minute, presence: true
  validates :leave_night_time_minute, presence: true
  validates :week_in_compensatory_minute, presence: true
  validates :week_out_compensatory_minute, presence: true
  validates :break_time_minute, presence: true

  before_validation :set_file_target, if: ->{ file }

  def day_time_minute
    is_holiday ? leave_day_time_minute : duty_day_time_minute
  end

  def night_time_minute
    is_holiday ? leave_night_time_minute : duty_night_time_minute
  end

  private

  def set_file_target
    self.target_user_id = file.target_user_id
    self.target_group_id = file.target_group_id
  end
end
