# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def user_logged_in?
    logged_in? && current_user.active?
  end

  def self.email_regex
    /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
  end

  def self.email_message
    'is not valid (should look like user@example.com)'
  end

end
