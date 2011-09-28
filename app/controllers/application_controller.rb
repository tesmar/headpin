#
# Copyright 2011 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

class CandlepinError < Exception; end;

class ApplicationController < ActionController::Base
  protect_from_forgery
  layout 'katello'
  helper_method :working_org
  before_filter :set_gettext_locale, :set_locale

  # This is a fairly giant hack to make the request
  # available to the Models for active record
  before_filter :store_request_in_thread
  after_filter :flash_to_headers

  # Global error handling, parsed bottom-up so most specific goes at the end:
  rescue_from CandlepinError, :with => :handle_candlepin_server_error
  rescue_from Errno::ECONNREFUSED, :with => :handle_candlepin_connection_error

  # Generic handler triggered whenever a controller action doesn't explicitly
  # do it's own error handling:
  def handle_generic_error ex
    log_exception(ex)
    errors _("An unexpected error has occurred, details have been logged.")
    redirect_back
  end

  # Handle ISE's from Candlepin:
  def handle_candlepin_server_error(ex)
    log_exception(ex)
    errors _("An error has occurred in the Entitlement Server.")
    redirect_back
  end

  # Handle ISE's from Candlepin:
  def handle_candlepin_connection_error ex
    log_exception(ex)
    render :text => _("Unable to connect to the Entitlement Server.")
  end

  def redirect_back
    begin
      redirect_to :back
    rescue ActionController::RedirectBackError
      redirect_to '/dashboard'
    end
  end

  # Small helper to keep logging of exceptions consistent:
  def log_exception ex
    logger.error ex
    logger.error ex.class
    logger.error ex.backtrace.join("\n")
  end

  def store_request_in_thread
      Thread.current[:request] = request
  end

  # Override this in subclasses to specify the
  # controller's section_id
  def section_id
    'generic'
  end

  def errors summary, failures = [], successes = []
    flash[:error] ||= {}
    flash[:error][:successes] = successes
    flash[:error][:failures] = failures
    flash[:error][:summary] = summary
  end
  
  def working_org
    org_id = session[:current_organization_id]
    @working_org ||= Organization.retrieve(org_id) unless org_id.nil?
    @working_org
  end

  def working_org=(org)
    @working_org = org
    session[:current_organization_id] = org.key if org
  end
  
  def logged_in_user
    @logged_in_user ||= current_user
  end

  #begin new orgs
  def allowed_orgs
    render :partial=>"/layouts/allowed_orgs", :locals =>{
        :working_org=>@organization = Organization.retrieve(session[:current_organization_id]),
        :visible_orgs=>Organization.retrieve_by_user(logged_in_user.username)
    }
  end

  def set_org
    @organization = Organization.retrieve(params[:workingorg])
    self.working_org = @organization
    flash[:notice] = N_("Now using organization '#{@organization.displayName}'.")
    redirect_to :back
  end

  private

  # TODO:  Refactor these two methods!
  def require_org
    # If no working org is set, just use the first one in the visible list.
    # For non-admins this will be their one and only org.
    if working_org.nil?
      self.working_org = Organization.retrieve_by_user(logged_in_user.username).first
    end
    true
  end

  def require_user
    if current_user.nil?
      #user not logged
      flash[:notice] = _("You must be logged in to access that page.")
      #save original uri and redirect to login page
      session[:original_uri] = request.request_uri
      redirect_to new_login_url
      return false
    end

    # Set the user so navigation can detect if tabs for admins should be shown:
    logged_in_user

    true
  end

  def require_admin
    unless logged_in_user.superAdmin?
      flash[:notice] = _("You must be an administrator to access that page.")
      redirect_to dashboard_index_url
      return false
    end

    true
  end

  def require_no_user
    if current_user
      flash[:notice] = _("Welcome Back!") + ", " + current_user.username
      redirect_to dashboard_index_url
      return false
    end
  end

  def set_locale
    I18n.locale = extract_locale_from_accept_language_header
  end

  # XXX like in katello, this is temporary. we need a more robust method,
  # such rack middleware or a rails plugin
  def extract_locale_from_accept_language_header
    locale = "en_US"
    locale = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first \
      if not request.env['HTTP_ACCEPT_LANGUAGE'].nil?
    return locale
  end

 # Generate a notice:
  #
  # notice:              The text to include
  # options:             Optional hash containing various optional parameters.  This includes:
  #   level:               The type of notice to be generated.  Supported values include:
  #                        :message, :success (Default), :warning, :error
  #   synchronous_request: true. if this notice is associated with an event where
  #                        the user would expect to receive a response immediately
  #                        as part of a response. This typically applies for events
  #                        involving things such as create, update and delete.
  #   persist:             true, if this notice should be stored via ActiveRecord.
  #                        Note: this option only applies when synchronous_request is true.
  #   list_items:          Array of items to include with the generated notice (text).  If included,
  #                        the array will be converted to a string (separated by newlines) and
  #                        concatenated with the notice text.  This is useful in scenarios where
  #                        there are several validation errors occur from a single form submit.
  #   details:             String containing additional details.  This would typically be to store
  #                        information such as a stack trace that is in addition to the notice text.
  def notice(notice, options = {})
    notice = "" if notice.nil?

    # set the defaults
    level = :success
    synchronous_request = true

    persist = true
    global = false
    details = nil

    unless options.nil?
      level = options[:level] unless options[:level].nil?
      synchronous_request = options[:synchronous_request] unless options[:synchronous_request].nil?
      persist = options[:persist] unless options[:persist].nil?
      global = options[:global] unless options[:global].nil?
      details = options[:details] unless options[:details].nil?
    end

    notice_dialog = build_notice notice, options[:list_items]

    notice_string = notice_dialog["notices"].join("<br />")
    if notice_dialog.has_key?("validation_errors")
      notice_string = notice_string + notice_dialog["validation_errors"].join("<br />")
    end

    if synchronous_request
      # On a sync request, the client should expect to receive a notification
      # immediately without polling.  In order to support this, we will send a flash
      # notice.
      if !details.nil?
        notice_dialog["notices"].push( _("#{self.class.helpers.link_to('Click here', notices_path)} for more details."))
      end

      flash[level] = notice_dialog.to_json

    else
      # On an async request, the client shouldn't expect to receive a notification
      # immediately. As a result, we'll store the notification and it will be
      # retrieved by the client on it's next polling interval.
      #
      # create & store notice... and mark as 'not viewed'
      Notice.create!(:text => notice_string, :details => details, :level => level, :global => global, :user_notices => [UserNotice.new(:user => current_user, :viewed=>false)])

    end
  end

  # Generate an error notice:
  #
  # summary:             the text to include
  # options:             Hash containing various optional parameters.  This includes:
  #   level:               The type of notice to be generated.  Supported values include:
  #                        :message, :success (Default), :warning, :error
  #   synchronous_request: true. if this notice is associated with an event where
  #                        the user would expect to receive a response immediately
  #                        as part of a response. This typically applies for events
  #                        involving things such as create, update and delete.
  #   persist:             true, if this notice should be stored via ActiveRecord.
  #                        Note: this option only applies when synchronous_request is true.
  #   list_items:          Array of items to include with the generated notice.  If included,
  #                        the array will be converted to a string (separated by newlines) and
  #                        concatenated with the notice text.  This is useful in scenarios where
  #                        there are several validation errors occur from a single form submit.
  #   details:             String containing additional details.  This would typically be to store
  #                        information such as a stack trace that is in addition to the notice text.
  def errors summary, options = {}
    options[:level] = :error
    notice summary, options
  end

  def build_notice notice, list_items
    items = { "notices" => [] }

    if notice.kind_of? Array
      notice.each do |item|
        handle_notice_type item, items
      end
    elsif notice.kind_of? String
      unless list_items.nil? or list_items.length == 0
        notice = notice + list_items.join("<br />")
      end
      items["notices"].push(notice)
    else
      handle_notice_type notice, items
    end
    return items
  end

  def handle_notice_type notice, items
    if notice.kind_of? ActiveRecord::RecordInvalid
      items["validation_errors"] = notice.record.errors.full_messages.to_a
      return items
    elsif notice.kind_of? RestClient::InternalServerError
      items["notices"].push(notice.response)
      return items
    elsif notice.kind_of? RuntimeError
      items["notices"].push(notice.message)
    else
      items["notices"].push(notice)
    end
  end

  def flash_to_headers
    return if @_response.nil? or @_response.response_code == 302
    return if flash.blank?
    [:error, :warning, :success, :message].each do |type|
      unless flash[type].nil? or flash[type].blank?
        @enc = CGI::escape(flash[type].gsub("\n","<br \\>"))
        response.headers['X-Message'] = @enc
        response.headers['X-Message-Type'] = type.to_s
        flash.delete(type)  # clear the flash
        return
      end
    end
  end

end
