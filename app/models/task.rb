class Task < ApplicationRecord

  # 論理削除使用
  # acts_as_paranoid

  ##
  # リレーション
  ##

  belongs_to :user

  ##
  # バリデーション
  ##

  # タスク名
  validates :task_name,
    presence: true,
    length: { maximum: 1000 }

  # uniqueness用のバリデーション
  # with_options if: :is_not_old? do
  #   validates :task_name, uniqueness: { scope: [:old_flg, :user_id] }
  # end

  ##
  # scopes
  ##

  # ユーザID
  # * [integer] value ユーザID
  # @return [Object] タスクのオブジェクト
  scope :user_id_is, -> (value) { where(user_id: value) }

  # タスク名称
  # * [string] value タスク名称
  # @return [Object] タスクのオブジェクト
  scope :name_is, -> (value) { where(task_name: value) }

  # タスクIDが引数と等しくない
  # * [integer] value タスクID
  # @return [Object] タスクのオブジェクト
  scope :id_is_not, -> (value) { where.not(id: value) }

  ##
  # methods
  ##

  # タスク重複チェック
  # @param  [integer] user_id 企業ID
  # @param  [string]  task_name タスク名
  # @return [Boolean]
  def self.task_name_duplicated?(user_id, task_name)
    !Task.user_id_is(user_id).name_is(task_name).blank?
  end

  # タスク重複チェック（編集時）
  # @param  [string]  id         タスクID
  # @param  [integer] user_id 企業ID
  # @param  [string]  task_name タスク名
  # @return [Boolean]
  def self.task_name_duplicated_for_edit?(id, user_id, task_name)
    !Task.id_is_not(id).user_id_is(user_id).name_is(task_name).blank?
  end

end
