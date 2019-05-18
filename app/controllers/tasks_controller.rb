class TasksController < ApplicationController
    before_action :sign_in_required, only: [:index]
    before_action :set_task, only: %i[update destroy]

    SESSION_KEY_FOR_PARAM = :task
  
    def index
      filter = Tasks::Filter.new
      @search_params = params

      @tasks = filter.search_tasks(@search_params)
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
        task = Tasks::Register.new(@task).delete(params[:id])
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

  end