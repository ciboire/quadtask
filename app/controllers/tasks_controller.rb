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
  
  def quad_edit
    @tree = Quadtree.find(session[:quadtree_id])
    new_title = params[:value] == '' ? 'unlabeled' : params[:value]
    case params[:quadrant]
    when "ImportantUrgent"
      @tree.important_urgent = new_title
    when "ImportantNotUrgent"
      @tree.important_not_urgent = new_title
    when "NotImportantUrgent"
      @tree.not_important_urgent = new_title
    else
      @tree.not_important_not_urgent = new_title
    end
    @tree.save
    render :text => new_title
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
    highlight_end_color = highlight_end_color_map(quadrant)
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
          page.replace_html 'newTaskEditorOuter' + quad, :partial => 'new_task_editor', :locals => {:quadrant => quad,
            :highlight_end_color => highlight_end_color}
        end
      end
    end
  end


  def tree_delete
    if params[:id].to_i == session[:quadtree_id]
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
      render :partial => 'title', :locals => {:task => @task, :quadrant => params[:quadrant], :highlight_end_color =>
        highlight_end_color_map(params[:quadrant])}
    else
      render :nothing => true
    end
  end
  
  
  def tree_check
    session[:quadtree_id] = params[:id].to_i
    redirect_to home_url
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
      highlight_end_color = highlight_end_color_map(quadrant)
      position = Task.maximum(:position, :conditions => {:is_important => important_map(quadrant), :is_urgent => urgent_map(quadrant)}) ?
        Task.maximum(:position, :conditions => {:is_important => important_map(quadrant), :is_urgent => urgent_map(quadrant)}) + 1 : 0
      @task = Task.new(:title => params[:value], :is_crossed_out => false, :is_important => important_map(quadrant),
        :is_urgent => urgent_map(quadrant), :position => position, :quadtree_id => session[:quadtree_id])
      if @task.save
        render :update do |page|
          page.insert_html :bottom, 'createdTasks' + quadrant, :partial => 'item_task', :locals => {:task => @task, :quadrant => quadrant,
              :highlight_end_color => highlight_end_color}
          page.sortable "createdTasks#{quadrant}", :constraint => false, 
            :containment => ['createdTasksNotImportantUrgent', 'createdTasksImportantUrgent', 'createdTasksImportantNotUrgent',
            'createdTasksNotImportantNotUrgent'], :dropOnEmpty => true,
            :url => {:action => 'task_sort', :quadrant => quadrant}, :handle => 'quadTaskTitle'
          page << "document.getElementById('newTask" + quadrant + "').scrollIntoView(true);"
          
          # Check for maxmimum tasks
          ['ImportantUrgent', 'NotImportantUrgent', 'ImportantNotUrgent', 'NotImportantNotUrgent'].each do |quad|
            page.replace_html 'newTaskEditorOuter' + quad, :partial => 'new_task_editor', :locals => {:quadrant => quad,
            :highlight_end_color => highlight_end_color}
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
    @quadtree = Quadtree.new(:user_id => current_user.id, :title => "(no name)", :position => position)
    
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
  
  def upgrade
  end
  
  def faq
    @faqs = Faq.find(:all)
  end
  
  #------------------------------------------------------------------------------------------------
  #
  # PDT callback.
  #
  def thanks
    bad_transaction = 'An error occurred while retrieving payment information from PayPal.<br />' \
    + 'Please contact support@vegaphysics.com for assistance.'

    tx_token = params['tx']

    if tx_token.blank?
      logger.info('Missing PayPal transaction token')
      flash[:alert] = bad_transaction
      return
    end

    if Payment.find_by_tx_token(tx_token)
      logger.info("Duplicate PayPal transaction token #{tx_token}")
      flash[:alert] = "We have already completed transaction #{tx_token}.<br /><br />Thank you for your payment.<br /><br />" \
      + " A receipt for your purchase was emailed to you."
      return
    end

    # Payment Data Transfer identity token from
    # PayPal.com > Profile > Website Payment Preferences
    id_token = 'PC-XFy7qV1jXUU9CCYCJPsJTlxXD5Vu5cfmzEuS0Lrx9qn4OUvcUeH-8ODy'
    uri = URI.parse('http://www.paypal.com/cgi-bin/webscr')

    request_path = "at=" + id_token + "&tx=" + tx_token + "&cmd=_notify-synch"
    logger.info "PDT query to PayPal: #{request_path}"

    response = nil

    Net::HTTP.start(uri.host, uri.port) do |request|
      response = request.post(uri.path, request_path).body
    end

    logger.info "PDT response from PayPal: #{response}"
    status = response.split[0]
    logger.info "PDT status: #{status}"

    unless 'SUCCESS' == status
      logger.info("Unexpected PDT status: #{status}")
      flash[:alert] = bad_transaction
      return
    end

    # Unpack the transaction details from the PDT into the params hash.
    response.each do |line|
      key, value = line.scan( %r{^(\w+)\=(.*)$} ).flatten
      params[key] = CGI.unescape(value) if key
    end

    # Check email address to prevent spoof payments.
    receiver_email = params['receiver_email']

    unless receiver_email == 'admin@vegaphysics.com'
      logger.info("Unexpected PDT receiver email: #{receiver_email}")
      flash[:alert] = bad_transaction
      return
    end

    custom = params['custom'].split
    user_id = custom[0]
    user_email = custom[1]
    description = "user_id: #{user_id}; user_email: #{user_email}"
    payment_gross = params['mc_gross']
    logger.info "PDT gross payment: #{payment_gross}"
    logger.info "PDT #{description}"
    logger.info "PDT custom: " + params['custom']
    
    # Save a copy of the transaction in case there is a dispute
    Payment.create(:description => description, :user_id => user_id, :user_email => user_email,
      :amount => payment_gross, :tx_token => tx_token)
    flash[:notice] = 'Thank you for your payment!  Your account upgrade is complete.'
    
    # Update User table to reflect successful transaction
    @user = User.find(user_id)
    @user.tx_token = tx_token
    @user.tx_accepted = true
    @user.membership_level = "premium"
    @user.save
  end


  #------------------------------------------------------------------------------------------------
  #
  # IPN callback.
  #
  # Receive asynchronous Instant Payment Notification POSTs from PayPal.
  # Verify the payload by echoing it back to PayPal.
  # Perform some sanity checks, then update the Payments table if
  # the transaction has completed.
  #
  def get_ipn
    logger.info "Incoming IPN raw: #{request.raw_post}"
    logger.info "Incoming IPN params: #{params}"

    # Reply to PayPal's notifier that we received its message.
    render :status => :ok, :nothing => true

    uri = URI.parse('http://www.paypal.com/cgi-bin/webscr')

    request_path = 'cmd=_notify-validate&' + request.raw_post
    logger.info "IPN query to PayPal: #{request_path}"

    response = nil

    # Echo the payload back to PayPal.
    Net::HTTP.start(uri.host, uri.port) do |request|
      response = request.post(uri.path, request_path).body
    end

    logger.info "IPN response from PayPal: #{response}"

    # Make sure the transaction is valid.
    unless 'VERIFIED' == response
      logger.info("Unexpected IPN status: #{response}")
      return
    end

    # Don't process the same transaction twice.
    tx_token = params['txn_id']
    if Payment.find_by_tx_token(tx_token)
      logger.info("Duplicate PayPal transaction ID #{tx_token}")
      return
    end

    # Check email address to prevent spoof payments.
    unless 'admin@vegaphysics.com' == params['receiver_email']
      logger.info("Unexpected IPN receiver email: #{params['receiver_email']}")
      return
    end

    # Save completed transactions only.
    unless 'Completed' == params['payment_status']
      logger.info("Unexpected IPN payment status: #{params['payment_status']}")
      return
    end
    
    custom = params['custom'].split
    user_id = custom[0]
    user_email = custom[1]
    description = "user_id: #{user_id}; user_email: #{user_email}"
    payment_gross = params['mc_gross']
    logger.info "IPN gross payment: #{payment_gross}"
    logger.info "IPN #{description}"
    logger.info "IPN custom: " + params['custom']
    
    # Save a copy of the transaction in case there is a dispute
    Payment.create(:description => description, :user_id => user_id, :user_email => user_email,
      :amount => payment_gross, :tx_token => tx_token)
    
    # Update Student table to reflect successful transaction
    @user = User.find(user_id)
    @user.tx_token = tx_token
    @user.tx_accepted = true
    @user.membership_level = "premium"
    @user.save
  end
    

  # Private functions
  def important_map(quadrant)
    ['ImportantUrgent', 'ImportantNotUrgent'].include?(quadrant)
  end

  def urgent_map(quadrant)
    ['ImportantUrgent', 'NotImportantUrgent'].include?(quadrant)
  end
  
  def highlight_end_color_map(quadrant)
    if quadrant == 'ImportantUrgent'
      '#fff0f0'
    elsif quadrant == 'ImportantNotUrgent'
      '#f0fff0'
    else
      '#f0f0f0'
    end
  end
end
