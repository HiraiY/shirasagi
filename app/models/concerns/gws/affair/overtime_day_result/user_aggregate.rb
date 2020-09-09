module Gws::Affair::OvertimeDayResult::UserAggregate
  extend ActiveSupport::Concern

  module ClassMethods
    def user_aggregate
      match_pipeline = self.criteria.selector
      group_pipeline = {
        _id: {
          user_id: "$target_user_id",
          date: "$date",
          capital_id: "$capital_id"
        },
        duty_day_time_minute: { "$sum" => "$duty_day_time_minute" },
        duty_night_time_minute: { "$sum" => "$duty_night_time_minute" },
        leave_day_time_minute: { "$sum" => "$leave_day_time_minute" },
        leave_night_time_minute: { "$sum" => "$leave_night_time_minute" },
        duty_day_in_work_time_minute: { "$sum" => "$duty_day_in_work_time_minute" },
        week_out_compensatory_minute: { "$sum" => "$week_out_compensatory_minute" },
        overtime_minute: { "$sum" => "$overtime_minute" }
      }
      pipes = []
      pipes << { "$match" => match_pipeline }
      pipes << { "$group" => group_pipeline }
      pipes << { "$sort" => { user_id: -1, date: -1 } }

      prefs = {}
      threshold = SS.config.gws.affair.dig("overtime", "aggregate", "threshold_hour") * 60

      subs = {}

      aggregation = self.collection.aggregate(pipes)
      aggregation.each do |i|
        user_id = i["_id"]["user_id"]
        capital_id = i["_id"]["capital_id"]

        subs[user_id] ||= {}
        subs[user_id]["detail_subtractor"] ||= Gws::Affair::Subtractor.new(threshold)
        subs[user_id]["total_subtractor"] ||= Gws::Affair::Subtractor.new(threshold)

        prefs[user_id] ||= {}
        prefs[user_id][0] ||= {}

        prefs[user_id][capital_id] ||= {}

        d_d_m = i["duty_day_time_minute"]
        d_n_m = i["duty_night_time_minute"]
        l_d_m = i["leave_day_time_minute"]
        l_n_m = i["leave_night_time_minute"]
        i_w_m = i["duty_day_in_work_time_minute"]
        w_c_m = i["week_out_compensatory_minute"]
        o_m = i["overtime_minute"]

        detail_under_minutes, detail_over_minutes = subs[user_id]["detail_subtractor"].subtract(d_d_m, d_n_m, l_d_m, l_n_m, i_w_m, w_c_m)
        total_under_minutes, total_over_minutes = subs[user_id]["total_subtractor"].subtract(o_m)

        prefs[user_id][capital_id]["under_threshold"] ||= {
          "duty_day_time_minute" => 0,
          "duty_night_time_minute" => 0,
          "leave_day_time_minute" => 0,
          "leave_night_time_minute" => 0,
          "duty_day_in_work_time_minute" => 0,
          "week_out_compensatory_minute" => 0,
          "overtime_minute" => 0
        }
        prefs[user_id][capital_id]["under_threshold"]["duty_day_time_minute"] += detail_under_minutes[0]
        prefs[user_id][capital_id]["under_threshold"]["duty_night_time_minute"] += detail_under_minutes[1]
        prefs[user_id][capital_id]["under_threshold"]["leave_day_time_minute"] += detail_under_minutes[2]
        prefs[user_id][capital_id]["under_threshold"]["leave_night_time_minute"] += detail_under_minutes[3]
        prefs[user_id][capital_id]["under_threshold"]["duty_day_in_work_time_minute"] += detail_under_minutes[4]
        prefs[user_id][capital_id]["under_threshold"]["week_out_compensatory_minute"] += detail_under_minutes[5]
        prefs[user_id][capital_id]["under_threshold"]["overtime_minute"] += total_under_minutes[0]

        prefs[user_id][0]["under_threshold"] ||= {
            "duty_day_time_minute" => 0,
            "duty_night_time_minute" => 0,
            "leave_day_time_minute" => 0,
            "leave_night_time_minute" => 0,
            "duty_day_in_work_time_minute" => 0,
            "week_out_compensatory_minute" => 0,
            "overtime_minute" => 0
        }
        prefs[user_id][0]["under_threshold"]["duty_day_time_minute"] += detail_under_minutes[0]
        prefs[user_id][0]["under_threshold"]["duty_night_time_minute"] += detail_under_minutes[1]
        prefs[user_id][0]["under_threshold"]["leave_day_time_minute"] += detail_under_minutes[2]
        prefs[user_id][0]["under_threshold"]["leave_night_time_minute"] += detail_under_minutes[3]
        prefs[user_id][0]["under_threshold"]["duty_day_in_work_time_minute"] += detail_under_minutes[4]
        prefs[user_id][0]["under_threshold"]["week_out_compensatory_minute"] += detail_under_minutes[5]
        prefs[user_id][0]["under_threshold"]["overtime_minute"] += total_under_minutes[0]

        prefs[user_id][capital_id]["over_threshold"] ||= {
          "duty_day_time_minute" => 0,
          "duty_night_time_minute" => 0,
          "leave_day_time_minute" => 0,
          "leave_night_time_minute" => 0,
          "week_out_compensatory_minute" => 0,
          "overtime_minute" => 0
        }
        prefs[user_id][capital_id]["over_threshold"]["duty_day_time_minute"] += (detail_over_minutes[0] + detail_over_minutes[4])
        prefs[user_id][capital_id]["over_threshold"]["duty_night_time_minute"] += detail_over_minutes[1]
        prefs[user_id][capital_id]["over_threshold"]["leave_day_time_minute"] += detail_over_minutes[2]
        prefs[user_id][capital_id]["over_threshold"]["leave_night_time_minute"] += detail_over_minutes[3]
        prefs[user_id][capital_id]["over_threshold"]["week_out_compensatory_minute"] += detail_over_minutes[5]
        prefs[user_id][capital_id]["over_threshold"]["overtime_minute"] += total_over_minutes[0]

        prefs[user_id][0]["over_threshold"] ||= {
          "duty_day_time_minute" => 0,
          "duty_night_time_minute" => 0,
          "leave_day_time_minute" => 0,
          "leave_night_time_minute" => 0,
          "week_out_compensatory_minute" => 0,
          "overtime_minute" => 0
        }
        prefs[user_id][0]["over_threshold"]["duty_day_time_minute"] += (detail_over_minutes[0] + detail_over_minutes[4])
        prefs[user_id][0]["over_threshold"]["duty_night_time_minute"] += detail_over_minutes[1]
        prefs[user_id][0]["over_threshold"]["leave_day_time_minute"] += detail_over_minutes[2]
        prefs[user_id][0]["over_threshold"]["leave_night_time_minute"] += detail_over_minutes[3]
        prefs[user_id][0]["over_threshold"]["week_out_compensatory_minute"] += detail_over_minutes[5]
        prefs[user_id][0]["over_threshold"]["overtime_minute"] += total_over_minutes[0]
      end

      prefs
    end
  end
end
