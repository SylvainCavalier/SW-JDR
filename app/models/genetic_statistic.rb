class GeneticStatistic < ApplicationRecord
  belongs_to :user

  def self.for_user(user)
    find_or_create_by(user: user)
  end

  def increment_stat!(stat_name)
    increment!(stat_name)
  end
end

