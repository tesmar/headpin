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
    :available_subscriptions, :unbind, :destroy, :update,
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


  def edit
    render :partial => 'edit', :layout => "tupane_layout"
  end

  def facts
    render :partial => 'edit_facts', :layout => "tupane_layout"
  end

  def events
    @events = Event.find_by_consumer(@system.uuid)
    render :partial => 'edit_events', :layout => "tupane_layout"
  end

  def subscriptions

    # Method currently used for both GET and POST, check if we're subscribing:
    if params.has_key?("pool_id")
      pool_id = params['pool_id']
      Rails.logger.info "#{@system.uuid} binding to pool #{pool_id}"
      ent = @system.bind(pool_id)
      product_name = Subscription.find(ent.pool.id).productName
      flash[:notice] = _("Subscribed to #{product_name}.")
    end

    @entitlements = Entitlement.find(:all, :params => {:consumer => @system.uuid})

    render :partial => "subscriptions", :layout => "tupane_layout"
  end

  def available_subscriptions
    @subscriptions = Subscription.find(:all, :params => {:consumer => @system.uuid})
    render :partial => "available_subscriptions" , :layout => "tupane_layout"
  end

  def unbind
    ent_id = params['entitlement_id']
    ent = Entitlement.find(ent_id, :system_id => @system.uuid)
    Rails.logger.info "#{@system.uuid} unbinding entitlement #{ent_id}"
    product_name = Subscription.find(ent.pool.id).productName
    ent.destroy
    flash[:notice] = _("Unsubscribed from #{product_name}.")
    redirect_to subscriptions_system_path(params['id'])
  end

  def destroy
    @system.destroy
    flash[:notice] = _("Deleted system #{@system.name}.")
    redirect_to systems_path
  end

  def update
    @system.update_attributes(params[:system])

    @system.save!

    respond_to do |format|
      format.html {render :text => params[:system].values.first}
      format.js
    end
  end

  def find_system
    @system = System.retrieve(params[:id])
    @organization = Organization.find @system.owner_key
  end

  def manifest_dl
    send_data(Candlepin::Consumer.cert_zip(params[:id]), :filename => "export.zip")
  end
end

