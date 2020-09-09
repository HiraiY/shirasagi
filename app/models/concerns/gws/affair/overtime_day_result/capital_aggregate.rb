module Gws::Affair::OvertimeDayResult::CapitalAggregate
  extend ActiveSupport::Concern

  module ClassMethods
    def capital_aggregate_by_month
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

        prefs[year][month]["total"] ||= 0
        prefs[year][month]["total"] += overtime_minute
      end
      prefs
    end

    def capital_aggregate_by_group
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

        prefs[group_id]["total"] ||= 0
        prefs[group_id]["total"] += overtime_minute
      end
      prefs
    end

    def capital_aggregate_by_users
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

        prefs[user_id]["total"] ||= 0
        prefs[user_id]["total"] += overtime_minute
      end
      prefs
    end
  end
end
