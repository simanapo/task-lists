class Tasks::Register

  # 初期化
  # @param [Object] task 使用地のオブジェクト
  # def initialize(task = nil)
  #   @task = task
  # end

  # 使用地を登録する
  # @param [Hash] request 入力データ（使用地モデル）
  # @param [Integer] company_id 企業ID
  # @return [Object] 使用地のオブジェクト
  # @raise [ActiveRecord::StatementInvalid] DBアクセス時に何らかのエラー
  # @raise [ValidationError] バリデーションエラー
  def insert(request, user_id)
    # ActiveRecord::Base.transaction(isolation: :read_committed) do
      # ::Task.user_id_is(user_id).lock.all.to_a
      task = ::Task.new(create_param(request, user_id))
      # fail DuplicatedError if Task.task_name_duplicated?(user_id, request['task_name'])
      task.save!
      task
    # end
  end

  # CSVファイルで一括登録するときの処理
  def insert_all(request, company_id)
    ActiveRecord::Base.transaction(isolation: :read_committed) do
      # ロックテーブルを行ロック
      ::Lock.find([company_id, ::Lock.processing_types[:place_registration]]).lock!
      ::Place.company_id_is(company_id).lock.all.to_a

      # 一括登録したいカラムの数
      place_column_length = 4.freeze

      result = {}
      # 総数
      result[:total_count] = request.count
      # 処理件数
      result[:process_count] = 0
      # エラーメッセージ一覧
      result[:errors] = []

      existing_places = {}
      existing_places[:place_name] = Place.company_id_is(company_id).pluck(:place_name)
      existing_places[:address]    = Place.company_id_is(company_id).pluck(:address)

      request.each_with_index do |value, index|
        is_register = true
        line_number = index + 2

        # カラムの個数チェック
        unless value.length == place_column_length
          is_register = false
          result[:errors] << "#{line_number}行目 カラムの数が正しくありません"
          next
        end

        next unless is_register

        place_param = format_place_params(value)
        @place = Place.company_id_is(company_id).build(place_param)

        if @place.valid?
          @place.save!
          result[:process_count] += 1
        else
          @place.errors.full_messages.each do |error|
            if existing_places[:place_name].exclude?(@place.place_name) && error.include?("使用地名はすでに存在します")
              result[:errors] << "#{line_number}行目 使用地名はCSVファイル内で重複しています"
            elsif existing_places[:address].exclude?(@place.address) && error.include?("住所はすでに存在します")
              result[:errors] << "#{line_number}行目 住所はCSVファイル内で重複しています"
            else
              result[:errors] << "#{line_number}行目 #{error}"
            end
          end
        end
      end

      # 件数フォーマット処理
      result[:total_count]   = result[:total_count].to_s(:delimited)
      result[:process_count] = result[:process_count].to_s(:delimited)
      if Company.find(company_id).parent_company_id
        result[:company_id] = Company.find(company_id).parent_company_id
        result[:subsidiary_company_id] = company_id
      else
        result[:company_id] = company_id
      end

      raise ActiveRecord::ActiveRecordError.new result.to_json if result[:errors].present?

      result
    end
  end

  # 使用地を更新する
  # @param [Hash] request 入力データ（使用地モデル）
  # @option request [DateTime] :updated_at 更新日時
  # @param [Integer] company_id 企業ID
  # @param [Integer] place_id 使用地ID
  # @return [Object] 使用地のオブジェクト
  # @raise [ActiveRecord::StatementInvalid] DBアクセス時に何らかのエラー
  # @raise [ValidationError] バリデーションエラー
  # @raise [AlreadyUpdated] 更新されていた
  def update(request, company_id, place_id)
    ActiveRecord::Base.transaction(isolation: :read_committed) do
      ::Lock.find([company_id, ::Lock.processing_types[:place_registration]]).lock!
      @place.lock!
      fail DuplicatedError if Place.task_name_duplicated_for_edit?(place_id, company_id, request['place_name'])
      @place.update! update_param request
      @place
    end
  end

  # 使用地を削除する
  # @param [Hash] request 送信データ
  # @option request [DateTime] :updated_at 更新日時
  # @param [Integer] place_id 使用地ID
  # @return [Bool] 削除に成功した場合はtrue、削除に失敗した場合はfalse
  # @raise [ActiveRecord::StatementInvalid] DBアクセス時に何らかのエラー
  # @raise [AlreadyDeleted] 更新データなし（削除されていた）
  def delete(request, company_id, place_id)
    ActiveRecord::Base.transaction(isolation: :read_committed) do
      ::Lock.find([company_id, ::Lock.processing_types[:place_registration]]).lock!
      @place.lock!
      # 対象使用地が使用されているか
      if ::Place.use_place?(place_id, company_id)
        @place.errors.add(:base, I18n.t('errors.messages.delete_permission', record: @place.place_name, reason: "対象使用地が使用されている"))
      end
      return @place if @place.errors.present?
      fail AlreadyDeleted if Place.exists?(id: place_id, old_flg: ::Place.old_flgs[:is_old])
      @place.update! delete_param
      @place
    end
  end

  private

  def update_param(request)
    { place_name:   request['place_name'],
      postal_code:  request['postal_code'],
      address:      request['address'],
      phone_number: request['phone_number'] }
  end

  def create_param(request, user_id)
    { user_id:   user_id,
      task_name:   request['task_name']}
  end

  def delete_param
    { old_flg: ::Place.old_flgs[:is_old] }
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
