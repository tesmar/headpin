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

class SystemsController < ApplicationController
  include AutoCompleteSearch

  respond_to :html, :js

  before_filter :require_user
  before_filter :require_org
  before_filter :find_system, :only => [:edit, :facts, :subscriptions,
    :available_subscriptions, :bind, :unbind, :destroy, :update,
    :events]

  def section_id
    'systems'
  end

  def index
    @systems = System.retrieve_all
  end

  def new
    @system = System.new
    render :partial=>"new", :layout => "tupane_layout", :locals=>{:system=>@system}
  end

  def create
    begin
      #{"method"=>"post", "system"=>{"name"=>"asdfsdf", "sockets"=>"asdfasdf", "arch"=>"asdfasdfasdf", "virtualized"=>"asdfasd"}, "authenticity_token"=>"n7hXf3d+YZZnvxqcjhQjPaDgSdl+xz2Xrzh2lCMRItI=", "utf8"=>"✓", "action"=>"create", "id"=>"new_system_form", "controller"=>"systems"}
      @system = System.new
      @system.arch = params["arch"]["arch_id"]
      @system.sockets = params["system"]["sockets"]
      @system.virtualized = params["system_type"]["virtualized"]
      @system.name = params["system"]["name"]
      @system.owner = working_org
      #create it in candlepin, parse the JSON and create a new ruby object to pass to the view
      @system = @system.create
      #find the newly created system
      flash[:notice] = N_("System '#{@system.name}' was created.")
    rescue Exception => error
      errors error.to_s
      Rails.logger.info error.backtrace.join("\n")
      render :text=> error.to_s, :status=>:bad_request and return
    end
    render :partial=>"common/list_item", :locals=>{:item=>@system, :accessor=>"uuid", :name => @system.name,
                                                   :columns=>['name', 'uuid']}
  end

  def edit
    render :partial => 'edit', :layout => "tupane_layout"
  end

  def facts
    render :partial => 'edit_facts', :layout => "tupane_layout"
  end

  def events
    @events = Event.retrieve_by_consumer(@system.uuid)
    render :partial => 'edit_events', :layout => "tupane_layout"
  end

  def subscriptions
    @entitlements = Entitlement.retrieve_all(@system.uuid)
    render :partial => "subscriptions", :layout => "tupane_layout"
  end

  def available_subscriptions
    @subscriptions = Subscription.retrieve_by_consumer_id(@system.uuid)
    render :partial => "available_subscriptions" , :layout => "tupane_layout"
  end

  def bind
    pool_id = params['pool_id']
    Rails.logger.info "#{@system.uuid} binding to pool #{pool_id}"
    ent = @system.bind(pool_id)
    product_name = Subscription.retrieve(ent.pool["id"]).product.name
    flash[:notice] = _("Subscribed to #{product_name}.")
    redirect_to available_subscriptions_system_path(params['id'])
  end

  def unbind
    ent_id = params['entitlement_id']
    ent = Entitlement.retrieve(ent_id)
    Rails.logger.info "#{@system.uuid} unbinding entitlement #{ent_id}"
    product_name = Subscription.retrieve(ent.pool["id"]).product.name
    successful = @system.unbind(ent_id)
    if successful
      #TODO fix the flash message
      flash[:notice] = _("Unsubscribed from #{product_name}.")
      redirect_to subscriptions_system_path(params['id'])
    else
      flash[:warning] = _("Failed to unsubscribe from #{product_name}.")
    end
  end

  def destroy
    @system.destroy
    flash[:notice] = _("Deleted system #{@system.name}.")
    redirect_to systems_path
  end

  def update
    @system.update(params[:system])

    respond_to do |format|
      format.html {render :text => params[:system].values.first}
      format.js
    end
  end

  def find_system
    @system = System.retrieve(params[:id])
    @organization = Organization.retrieve(@system.owner_key)
  end

  def manifest_dl
    send_data(Candlepin::Consumer.cert_zip(params[:id]), :filename => "certificates.zip")
  end
end

