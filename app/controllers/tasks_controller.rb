class TasksController < ApplicationController
    before_action :sign_in_required, only: [:index]
    before_action :set_task, only: %i[update_confirm update destroy sort]

    SESSION_KEY_FOR_PARAM = :task
  
    def index
      filter = Tasks::Filter.new
      @search_params = params

      @tasks = filter.search_tasks(@search_params)

      # if params[:task_name].present?
      #   @tasks = Task.name_is(params[:task_name]).is_not_old
      # else
      #   @tasks = Task.all.is_not_old
      # end
      @task = Task.new
      @user = User.find(current_user.id)
    end

  
    def create
      @task = Task.new task_params
      @task.save
      redirect_to action: "index"
    end
  
    def update
      task = Tasks::Register.new(@task).update(task_params, current_user.id, task_params[:id])
      redirect_to action: "index"
    end

    def destroy
        task = Tasks::Register.new(@task).delete(task_params[:id])
        redirect_to action: "index"
    end
  
    private
  
    # パラメータから取得したIDから、タスクを取得
    # @return [Object] @task タスクオブジェクト
    def set_task
      @task = Task.find(params[:id])
    end
  
    # パラメータ取得
    # @return [Hash] params パラメータ
    # @note ストロングパラメータ
    def task_params
      params.require(:task).permit(
        :id,
        :task_name,
        :user_id,
        :updated_at,
      )
    end
  
    # タスク重複チェックを呼び出す
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

  end
  