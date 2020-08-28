require 'spec_helper'

describe "gws_affair_duty_notices", type: :feature, dbscope: :example do
  context "basic crud", js: true do
    let(:site) { gws_site }

    context "time limit of month" do
      let(:duty_notice) { create(:gws_affair_duty_notice, notice_type: "month_time_limit") }
      let!(:duty_calendar) do
        create(
          :gws_affair_duty_calendar,
          flextime_state: "enabled",
          duty_notice_ids: [duty_notice.id],
          user_ids: [gws_user.id]
        )
      end

      it do

      end
    end
  end
end
