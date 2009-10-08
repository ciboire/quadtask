class TasksController < ApplicationController
  
  before_filter :login_required, :except => [:welcome, :index]
  
  in_place_edit_for :task, :title
  
  #
  # Landing page
  #
  def welcome
  end
  
  
  # 
  # Main page with quadrants, login etc.
  #
  def index
    if logged_in?
      @quadtrees = Quadtree.find(:all, :conditions => {:user_id => current_user.id}, :order => :position)
      if !session[:quadtree_id]
        if @quadtrees.size > 0
          session[:quadtree_id] = @quadtrees[0].id
        end
      end
      @tasks_important_urgent = Task.find(:all, :conditions => {:is_important => true,
        :is_urgent => true, :quadtree_id => session[:quadtree_id]}, :order => :position)
      @tasks_not_important_urgent = Task.find(:all, :conditions => {:is_important => false, 
        :is_urgent => true, :quadtree_id => session[:quadtree_id]}, :order => :position)
      @tasks_important_not_urgent = Task.find(:all, :conditions => {:is_important => true, 
        :is_urgent => false, :quadtree_id => session[:quadtree_id]}, :order => :position)
      @tasks_not_important_not_urgent = Task.find(:all, :conditions => {:is_important => false, 
        :is_urgent => false, :quadtree_id => session[:quadtree_id]}, :order => :position)

    else
      redirect_to :welcome
    end
  end
  
  
  def task_edit
    quadrant = params[:quadrant]
    id = params[:id]
    @task = Task.find(id)
    @task.title = params[:value]
    if @task.title == ''
      render :update do |page|
        page.remove('quadtask_' + id.to_s)
        page.sortable "createdTasks#{quadrant}", :constraint => false, 
          :containment => ['createdTasksNotImportantUrgent', 'createdTasksImportantUrgent', 'createdTasksImportantNotUrgent',
          'createdTasksNotImportantNotUrgent'], :dropOnEmpty => true,
          :url => {:action => 'task_sort', :quadrant => quadrant}, :handle => 'quadTaskTitle'
        @task.destroy
      end
    else
      @task.save
      render :text => @task.title
    end
  end
  
  
  def tree_edit
    id = params[:id]
    @tree = Quadtree.find(id)
    @tree.title = params[:value]
    if @tree.title == ''
      render :update do |page|
        page.remove('quadtree_' + id.to_s)
        page.sortable "quadtreeListId", :constraint => 'vertical', 
          :containment => ['quadtreeListId'], :url => {:action => 'tree_sort'}, :handle => 'quadtreeItem'
        @tree.destroy
      end
    else
      @tree.save
      render :text => @tree.title
    end
  end

  
	def task_sweep
    quadrant = params[:quadrant]
    @tasks = Task.find(:all, :conditions => {:is_important => important_map(quadrant), :is_urgent => urgent_map(quadrant),
      :is_crossed_out => true})
    render :update do |page|
      @tasks.each do |task|
        page.visual_effect :fade, 'quadtask_' + task.id.to_s, :duration => 1.0
      end
      page.delay(1.5) do
        @tasks.each do |task|
          page.remove('quadtask_' + task.id.to_s)
          page.sortable "createdTasks#{quadrant}", :constraint => false, 
            :containment => ['createdTasksNotImportantUrgent', 'createdTasksImportantUrgent', 'createdTasksImportantNotUrgent',
            'createdTasksNotImportantNotUrgent'], :dropOnEmpty => true,
            :url => {:action => 'task_sort', :quadrant => quadrant}, :handle => 'quadTaskTitle'
          task.destroy
        end
      end
    end
  end
  
  
  def task_delete
    quadrant = params[:quadrant]
    @task = Task.find(params[:task_id])
    render :update do |page|
      page.visual_effect :fade, 'quadtask_' + @task.id.to_s, :duration => 1.0
      page.delay(1.5) do
        page.remove('quadtask_' + @task.id.to_s)
        page.sortable "createdTasks#{quadrant}", :constraint => false, 
          :containment => ['createdTasksNotImportantUrgent', 'createdTasksImportantUrgent', 'createdTasksImportantNotUrgent',
          'createdTasksNotImportantNotUrgent'], :dropOnEmpty => true,
          :url => {:action => 'task_sort', :quadrant => quadrant}, :handle => 'quadTaskTitle'
        @task.destroy
        
        # Check for maxmimum tasks
        ['ImportantUrgent', 'NotImportantUrgent', 'ImportantNotUrgent', 'NotImportantNotUrgent'].each do |quad|
          page.replace_html 'newTaskEditorOuter' + quad, :partial => 'new_task_editor', :locals => {:quadrant => quad}
        end
      end
    end
  end


  def tree_delete
    if params[:id] == session[:quadtree_id]
      session[:quadtree_id] = nil
    end
    @tree = Quadtree.find(params[:id])
    @tree.destroy
    redirect_to manage_url
  end
  
  
  def task_check
    @task = Task.find(params[:id])
    @task.is_crossed_out = !@task.is_crossed_out
    if @task.save
      render :partial => 'title', :locals => {:task => @task, :quadrant => params[:quadrant]}
    else
      render :nothing => true
    end
  end
  
  
  def tree_check
    session[:quadtree_id] = params[:id]
    redirect_to 'index'
  end
  
  
  def task_sort
    quadrant = params[:quadrant]
    neworder = params['createdTasks' + quadrant]
    position = 0
    if neworder
      neworder.each do |id|
        @task = Task.find(id)
        @task.position = position
        @task.is_urgent = urgent_map(quadrant)
        @task.is_important = important_map(quadrant)
        @task.save
        position += 1
      end
    end
    render :nothing => true
  end
  
  
  def tree_sort
    neworder = params['quadtreeListId']
    position = 0
    if neworder
      neworder.each do |id|
        @tree = Quadtree.find(id)
        @tree.position = position
        @tree.save
        position += 1
      end
    end
    render :nothing => true
  end
  
  
  def task_create
    unless params[:value] == ''
      quadrant = params[:quadrant]
      position = Task.maximum(:position, :conditions => {:is_important => important_map(quadrant), :is_urgent => urgent_map(quadrant)}) ?
        Task.maximum(:position, :conditions => {:is_important => important_map(quadrant), :is_urgent => urgent_map(quadrant)}) + 1 : 0
      @task = Task.new(:title => params[:value], :is_crossed_out => false, :is_important => important_map(quadrant),
        :is_urgent => urgent_map(quadrant), :position => position, :quadtree_id => session[:quadtree_id])
      if @task.save
        render :update do |page|
          page.insert_html :bottom, 'createdTasks' + quadrant, :partial => 'item_task', :locals => {:task => @task, :quadrant => quadrant}
          page.sortable "createdTasks#{quadrant}", :constraint => false, 
            :containment => ['createdTasksNotImportantUrgent', 'createdTasksImportantUrgent', 'createdTasksImportantNotUrgent',
            'createdTasksNotImportantNotUrgent'], :dropOnEmpty => true,
            :url => {:action => 'task_sort', :quadrant => quadrant}, :handle => 'quadTaskTitle'
          page << "document.getElementById('newTask" + quadrant + "').scrollIntoView(true);"
          
          # Check for maxmimum tasks
          ['ImportantUrgent', 'NotImportantUrgent', 'ImportantNotUrgent', 'NotImportantNotUrgent'].each do |quad|
            page.replace_html 'newTaskEditorOuter' + quad, :partial => 'new_task_editor', :locals => {:quadrant => quad}
          end
        end
      else
        render :nothing => true
      end
    else
      render :text => 'Enter new task...'
    end
  end
  
  
  def tree_create
    position = Quadtree.maximum(:position, :conditions => {:user_id => current_user.id}) ?
      Quadtree.maximum(:position, :conditions => {:user_id => current_user.id}) + 1 : 0
    @quadtree = Quadtree.new(:user_id => current_user.id, :title => "new group", :position => position)
    
    if @quadtree.save
      redirect_to manage_url
    else
      render :nothing => true
    end
  end
  
  def tree_manage
    @quadtrees = Quadtree.find(:all, :conditions => {:user_id => current_user.id}, :order => :position)
    render :action => 'quadoptions'
  end
    
  

  # Private functions
  def important_map(quadrant)
    ['ImportantUrgent', 'ImportantNotUrgent'].include?(quadrant)
  end

  def urgent_map(quadrant)
    ['ImportantUrgent', 'NotImportantUrgent'].include?(quadrant)
  end
end
