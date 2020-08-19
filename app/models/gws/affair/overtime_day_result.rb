class Gws::Affair::OvertimeDayResult
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Affair::FileTarget
  include Gws::Affair::OvertimeDayResult::UserAggregate
  include Gws::Affair::OvertimeDayResult::GroupAggregate

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

  class << self
    def aggregate_by_group
      match_pipeline = self.criteria.selector
      group_pipeline = {
        _id: {
          group_id: "$target_group_id",
          capital_id: "$capital_id"
        },
        overtime_minute: { "$sum" => "$overtime_minute" }
      }
      pipes = []
      pipes << { "$match" => match_pipeline }
      pipes << { "$group" => group_pipeline }

      prefs = {}
      aggregation = self.collection.aggregate(pipes)
      aggregation.each do |i|
        group_id = i["_id"]["group_id"]
        capital_id = i["_id"]["capital_id"]
        overtime_minute = i["overtime_minute"]

        prefs[group_id] ||= {}
        prefs[group_id][capital_id] = overtime_minute
      end
      prefs
    end

    def aggregate_by_group_users
      match_pipeline = self.criteria.selector
      group_pipeline = {
        _id: {
          user_id: "$target_user_id",
          capital_id: "$capital_id"
        },
        overtime_minute: { "$sum" => "$overtime_minute" }
      }
      pipes = []
      pipes << { "$match" => match_pipeline }
      pipes << { "$group" => group_pipeline }

      prefs = {}
      aggregation = self.collection.aggregate(pipes)
      aggregation.each do |i|
        user_id = i["_id"]["user_id"]
        capital_id = i["_id"]["capital_id"]
        overtime_minute = i["overtime_minute"]

        prefs[user_id] ||= {}
        prefs[user_id][capital_id] = overtime_minute
      end
      prefs
    end

    def aggregate_by_month
      match_pipeline = self.criteria.selector
      group_pipeline = {
        _id: {
          year: "$date_year",
          month: "$date_month",
          capital_id: "$capital_id"
        },
        overtime_minute: { "$sum" => "$overtime_minute" }
      }
      pipes = []
      pipes << { "$match" => match_pipeline }
      pipes << { "$group" => group_pipeline }

      prefs = {}
      aggregation = self.collection.aggregate(pipes)
      aggregation.each do |i|
        year = i["_id"]["year"]
        month = i["_id"]["month"]
        capital_id = i["_id"]["capital_id"]
        overtime_minute = i["overtime_minute"]

        prefs[year] ||= {}
        prefs[year][month] ||= {}
        prefs[year][month][capital_id] = overtime_minute
      end
      prefs
    end
  end
end
