class Tasks::Filter
  include ActiveModel::Model

  attr_accessor \
    :task_name, :status

  # 絞り込み検索
  # @param [Integer] request パラメータ
  # @return [Hash] タスクマスタ配列
  # @return [nil] 検索結果が無い場合
  # @raise [ActiveRecord::StatementInvalid] DBアクセス時に何らかのエラー
  def search_tasks(request)
    query = ::Task.all

    query = query.merge(::Task.where(task_name: task_name)) if task_name.present?

    if status == 'all'
      query = query.merge(::Task.is_not_old) if status.present?
    elsif status == 'only_deleted'
      query = query.merge(::Task.is_old) if status.present?
    end

    query
  end

end