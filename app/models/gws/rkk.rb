# 権限判定用モデル
class Gws::RKK
  include Gws::SitePermission

  set_permission_name "gws_rkk", :use
end
