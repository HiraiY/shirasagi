class Cms::AccessRankingTask
  include SS::Model::Task

  field :last_checked, type: DateTime
end
