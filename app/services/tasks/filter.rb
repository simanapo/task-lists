class Tasks::Filter
  include ActiveModel::Model

  # 絞り込み検索
  # @param [Integer] request パラメータ
  # @return [Hash] タスクマスタ配列
  # @return [nil] 検索結果が無い場合
  # @raise [ActiveRecord::StatementInvalid] DBアクセス時に何らかのエラー
  def search_tasks(request)

    query = ::Task.all

    query = query.merge(::Task.where(task_name: request[:task_name])) if request[:task_name].present?
    Rails.logger.info("--------------------------------------------")
    if request[:status] == 'all'
      query = query.merge(::Task.is_not_old) if request[:status].present?
    elsif request[:status] == 'only_deleted'
      query = query.merge(::Task.is_old) if request[:status].present?
    end

    query
  end

end