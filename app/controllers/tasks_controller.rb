class TasksController < ApplicationController
    before_action :sign_in_required, only: [:index]
    before_action :set_task, only: %i[update_confirm update destroy sort]

    SESSION_KEY_FOR_PARAM = :task
  
    # GET /tasks
    # GET /tasks.json
    def index
      @task = Task.new
      @tasks = Task.all
      @user = User.find(current_user.id)
    end

  
    def confirm
      @task = Task.new task_params
      if @task.save
        redirect_to action: "index"
      else
        render 'index'
      end
    end
  
    def update_confirm
      respond_to do |format|
        @task.assign_attributes(task_params)
        task = validate_on_confirm(@task, task_params[:updated_at])
        if task.errors.blank?
          session[SESSION_KEY_FOR_PARAM] = task_params
          format.json { render json: task, status: :ok }
        else
          format.json { fail AsyncRetryValidationError, task.errors }
        end
      end
    end
  
    # POST /tasks
    # POST /tasks.json
    def create
      respond_to do |format|
        request = session[SESSION_KEY_FOR_PARAM]
        task = Tasks::Register.new
        task.insert(request, request[:user_id])
        session[SESSION_KEY_FOR_PARAM] = nil
        format.json { render json: task, status: :ok }
      end
    end
  
    # PATCH/PUT /tasks/1
    # PATCH/PUT /tasks/1.json
    def update
      respond_to do |format|
        request = session[SESSION_KEY_FOR_PARAM]
        task = Tasks::Register.new(@task).update(request, @task.company_id, params[:id])
        session[SESSION_KEY_FOR_PARAM] = nil
        format.json { render json: task, status: :ok }
      end
    end
  
    # DELETE /tasks/1
    # DELETE /tasks/1.json
    def destroy
      respond_to do |format|
        request = {}
        request[:updated_at] = params[:updated_at]
        task = Tasks::Register.new(@task).delete(request, @task.company_id, params[:id])
        if task.errors.blank?
          format.json { render json: task, status: :ok }
        else
          format.json { fail AsyncRetryValidationError, task.errors }
        end
      end
    end
  
    # D&Dで並べ替えるためのメソッド
    def sort
      @task.update(task_params)
      render body: nil
    end
  
    private
  
    # パラメータから取得したIDから、使用地を取得
    # @return [Object] @task 使用地オブジェクト
    def set_task
      @task = Task.find(params[:id])
    end
  
    # パラメータ取得
    # @return [Hash] params パラメータ
    # @note ストロングパラメータ
    def task_params
      params.require(:task).permit(
        :task_name,
        :user_id,
        :updated_at,
      )
    end
  
    # バリデーションチェック
    # @param [Object] task 使用地オブジェクト
    # @param [DateTime] updated_at 更新日時
    # @return [Object] task 使用地オブジェクト
    def validate_on_confirm(task, updated_at = nil)
      task.validate
      task_name_duplicated = call_task_name_duplicated?(updated_at) if updated_at.present?
      task_name_duplicated = call_task_name_duplicated? unless updated_at.present?
      task.errors.add(
        :task_name,
        I18n.t('errors.messages.uniqueness', value: task_params[:task_name])
      ) if task_name_duplicated
      task
    end
  
    # 使用地重複チェックを呼び出す
    # @param [DateTime] updated_at 更新日時
    # @return [Bool] 重複している場合はtrue、重複していない場合はfalse
    def call_task_name_duplicated?(updated_at = nil)
      if updated_at.nil?
        Task.task_name_duplicated?(
          task_params[:user_id],
          task_params[:task_name]
        )
      else
        Task.task_name_duplicated_for_edit?(
          params[:id],
          task_params[:user_id],
          task_params[:task_name]
        )
      end
    end
  
    def opc_and_sales_only!
      raise ::ForbiddenError.new unless current_user.opc_admin_user? || current_user.sales_admin_user?
    end
  
    def opc_only!
      raise ::ForbiddenError.new unless current_user.opc_admin_user?
    end

  end
  