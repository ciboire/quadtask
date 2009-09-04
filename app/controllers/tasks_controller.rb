class TasksController < ApplicationController
  
  in_place_edit_for :task, :title
  
  # 
  # Main page with quadrants, login etc.
  #
  def index
    @tasks_important_urgent = Task.find(:all, :conditions => {:is_important => true, :is_urgent => true}, :order => :position)
    @tasks_not_important_urgent = Task.find(:all, :conditions => {:is_important => false, :is_urgent => true}, :order => :position)
    @tasks_important_not_urgent = Task.find(:all, :conditions => {:is_important => true, :is_urgent => false}, :order => :position)
    @tasks_not_important_not_urgent = Task.find(:all, :conditions => {:is_important => false, :is_urgent => false}, :order => :position)
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
          :url => {:action => 'task_sort', :quadrant => quadrant}, :handle => 'quadTaskHandle'
        @task.destroy
      end
    else
      @task.save
      render :text => @task.title
    end
  end
  
  def task_sweep
    quadrant = params[:quadrant]
    @tasks = Task.find(:all, :conditions => {:is_important => important_map(quadrant), :is_urgent => urgent_map(quadrant),
      :is_crossed_out => true})
    render :update do |page|
      @tasks.each do |task|
        page.visual_effect :fade, "quadtask_#{task.id}", :duration => 1.0, :fps => 100
      end
      page.delay(1.5) do
        @tasks.each do |task|
          page.remove('quadtask_' + task.id.to_s)
          page.sortable "createdTasks#{quadrant}", :constraint => false, 
            :containment => ['createdTasksNotImportantUrgent', 'createdTasksImportantUrgent', 'createdTasksImportantNotUrgent',
            'createdTasksNotImportantNotUrgent'], :dropOnEmpty => true,
            :url => {:action => 'task_sort', :quadrant => quadrant}, :handle => 'quadTaskHandle'
          task.destroy
        end
      end
    end
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
  
  def task_create
    unless params[:value] == ''
      quadrant = params[:quadrant]
      position = Task.maximum(:position, :conditions => {:is_important => important_map(quadrant), :is_urgent => urgent_map(quadrant)}) ?
        Task.maximum(:position, :conditions => {:is_important => important_map(quadrant), :is_urgent => urgent_map(quadrant)}) + 1 : 0
      @task = Task.new(:title => params[:value], :is_crossed_out => false, :is_important => important_map(quadrant),
        :is_urgent => urgent_map(quadrant), :position => position)
      if @task.save
        render :update do |page|
          page.insert_html :bottom, 'createdTasks' + quadrant, :partial => 'item_task', :locals => {:task => @task, :quadrant => quadrant}
          page.sortable "createdTasks#{quadrant}", :constraint => false, 
            :containment => ['createdTasksNotImportantUrgent', 'createdTasksImportantUrgent', 'createdTasksImportantNotUrgent',
            'createdTasksNotImportantNotUrgent'], :dropOnEmpty => true,
            :url => {:action => 'task_sort', :quadrant => quadrant}, :handle => 'quadTaskHandle'
          page << "document.getElementById('newTask" + quadrant + "').scrollIntoView(true);"
        end
      else
        render :nothing => true
      end
    else
      render :text => 'Enter new task...'
    end
  end

  # Private functions
  def important_map(quadrant)
    ['ImportantUrgent', 'ImportantNotUrgent'].include?(quadrant)
  end

  def urgent_map(quadrant)
    ['ImportantUrgent', 'NotImportantUrgent'].include?(quadrant)
  end
end
