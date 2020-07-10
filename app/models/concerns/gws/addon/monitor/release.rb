module Gws::Addon::Monitor
  module Release
    extend ActiveSupport::Concern
    extend SS::Addon
    include SS::Release

    included do
      self.default_release_state = 'draft'
    end

    # override SS::Release#state_with_release_date
    def state_with_release_date
      now = Time.zone.now
      return state if state != 'public'
      return 'closed' if release_date.present? && release_date > now
      return 'closed' if close_date.present? && close_date < now
      'public'
    end

    # override SS::Release#state_options
    def state_options
      %w(draft public closed).map { |m| [I18n.t("gws/monitor.options.state.#{m}"), m] }
    end
  end
end
