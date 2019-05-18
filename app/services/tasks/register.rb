class Tasks::Register

  # 初期化
  # @param [Object] task タスクのオブジェクト
  def initialize(task = nil)
    @task = task
  end

  # タスクを登録する
  # @param [Hash] request 入力データ（タスクモデル）
  # @param [Integer] company_id 企業ID
  # @return [Object] タスクのオブジェクト
  # @raise [ActiveRecord::StatementInvalid] DBアクセス時に何らかのエラー
  # @raise [ValidationError] バリデーションエラー
  def insert(request, user_id)
    ActiveRecord::Base.transaction do
      task = ::Task.new(create_param(request, user_id))
      fail DuplicatedError if Task.task_name_duplicated?(user_id, request['task_name'])
      task.save!
      task
    end
  end

  # タスクを更新する
  # @param [Hash] request 入力データ（タスクモデル）
  # @option request [DateTime] :updated_at 更新日時
  # @param [Integer] user_id 企業ID
  # @param [Integer] task_id タスクID
  # @return [Object] タスクのオブジェクト
  # @raise [ActiveRecord::StatementInvalid] DBアクセス時に何らかのエラー
  # @raise [ValidationError] バリデーションエラー
  # @raise [AlreadyUpdated] 更新されていた
  def update(request, user_id, task_id)
    ActiveRecord::Base.transaction do
      @task.lock!
      fail DuplicatedError if Task.task_name_duplicated_for_edit?(task_id, user_id, request['task_name'])
      @task.update! update_param request
      @task
    end
  end

  # タスクを削除する
  # @param [Hash] request 送信データ
  # @option request [DateTime] :updated_at 更新日時
  # @param [Integer] task_id タスクID
  # @return [Bool] 削除に成功した場合はtrue、削除に失敗した場合はfalse
  # @raise [ActiveRecord::StatementInvalid] DBアクセス時に何らかのエラー
  # @raise [AlreadyDeleted] 更新データなし（削除されていた）
  def delete(company_id, task_id)
    ActiveRecord::Base.transaction do
      @task.lock!
      fail AlreadyDeleted if Task.exists?(id: task_id, old_flg: ::Task.old_flgs[:is_old])
      @task.update! delete_param
      @task
    end
  end

  private

  def update_param(request)
    { task_name:   request['task_name']}
  end

  def create_param(request, user_id)
    { user_id:   user_id,
      task_name:   request['task_name']}
  end

  def delete_param
    { old_flg: ::Task.old_flgs[:is_old] }
  end

  # CSVデータから取得したパラメーターをフォーマット
  # @param [Array] params
  # @return [Hash] formatted_parameter
  def format_place_params(params)
    column_name_list = [
      :place_name,
      :postal_code,
      :address,
      :phone_number
    ]

    formatted_parameter = {}
    params.each_with_index do |value, index|
      if value.present?
        # 全角半角スペーストリム
        value&.gsub!(/[\s| ]+/, '')
      end
      formatted_parameter[column_name_list[index]] = value
    end
    formatted_parameter
  end
end
