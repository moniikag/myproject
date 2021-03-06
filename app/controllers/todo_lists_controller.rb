class TodoListsController < ApplicationController
  before_action :get_resources

  def index
    authorize TodoList
    @todo_lists = policy_scope(TodoList)
  end

  def create
    authorize TodoList
    @todo_list = current_user.todo_lists.new(permitted_attributes(TodoList.new))
    if @todo_list.save
      redirect_to todo_list_path(@todo_list)
    else
      redirect_to todo_lists_path
    end
  end

  def show
    @todo_lists = policy_scope(TodoList)
    @todo_items_complete = @todo_list.todo_items.complete.map { |todo_item| TodoItemPresenter.new(todo_item) }
    @todo_items_incomplete = @todo_list.todo_items.incomplete
      .order('priority ASC')
      .map { |todo_item| TodoItemPresenter.new(todo_item) }
  end

  def search
    authorize TodoList
    @todo_lists = policy_scope(TodoList)
    @search = params[:search].downcase
    @todo_items = SearchItems.call(
      lists: @todo_lists,
      items: policy_scope(TodoItem),
      searched_fraze: @search)
  end

  def update
    if @todo_list.update_attributes(permitted_attributes(@todo_list))
      respond_to do |format|
        format.html { redirect_to @todo_list, notice: 'Todo list was successfully updated.' }
        format.json { render json: @todo_list }
      end
    else
      render nothing: true
    end
  end

  def prioritize
    PrioritizeItems.call(items: @todo_list.todo_items, ids_in_order: params[:ordered_items_ids])
    render nothing: true
  end

  def done
    @todo_list.todo_items.map {
      |item| item.update_attribute(:completed_at, Time.now) if item.completed_at == nil
    }
    render nothing: true
  end

  def destroy
    @todo_lists = policy_scope(TodoList)
    if @todo_list.destroy
      redirect_to todo_lists_url
    else
      redirect_to root_path
    end
  end

  private
  def get_resources
    @todo_list = policy_scope(TodoList).find(params[:id]) if params[:id]
    if @todo_list
      authorize @todo_list
    else
      authorize TodoList
    end
  end
end
