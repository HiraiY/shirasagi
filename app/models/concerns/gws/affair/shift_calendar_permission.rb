module Gws::Affair::ShiftCalendarPermission
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Permission

  included do
    class_variable_set(:@@_permission_include_custom_groups, nil)
  end

  def owned?(in_user)
    in_user.id == user.id
  end

  def allowed?(action, in_user, opts = {})
    in_user = in_user.gws_user
    site = opts[:site] || @cur_site
    action = permission_action || action

    permits = []
    permits << "#{action}_other_#{self.class.permission_name}_#{site.id}"
    permits << "#{action}_private_#{self.class.permission_name}_#{site.id}" if (user.group_ids & in_user.group_ids).present?

    permits.map { |permit| in_user.gws_role_permissions[permit] }.compact.present?
  end

  private

  module ClassMethods
    def allowed?(action, in_user, opts = {})
      in_user = in_user.gws_user
      site = opts[:site] || @cur_site
      action = permission_action || action
      other = opts[:other]

      permits = []
      permits << "#{action}_other_#{permission_name}_#{site.id}"
      permits << "#{action}_private_#{permission_name}_#{site.id}"

      permits.map { |permit| in_user.gws_role_permissions[permit] }.compact.present?
    end

    def allowed_private?(action, in_user, opts = {})
      allowed?(action, in_user, opts)
    end

    def allowed_other?(action, in_user, opts = {})
      in_user = in_user.gws_user
      site = opts[:site] || @cur_site
      action = permission_action || action

      permits = []
      permits << "#{action}_other_#{permission_name}_#{site.id}"

      permits.map { |permit| in_user.gws_role_permissions[permit] }.compact.present?
    end
  end
end
