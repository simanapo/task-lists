class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # OLDフラグ
  enum old_flg: { is_not_old: 0, is_old: 1 }

  ##
  # scopes
  ##

  # OLDフラグ_IS
  scope :old_flg_is, -> (value) { where(old_flg: value) }
end
