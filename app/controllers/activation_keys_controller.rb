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

class ActivationKeysController < ApplicationController
  include AutoCompleteSearch
  respond_to :html, :js

  navigation :systems
  before_filter :require_user
  before_filter :require_org
  before_filter :find_activation_key, :only => [:edit, :update, :destroy] 

  def section_id
    'admin'
  end

  def new
    @subscriptions = Subscription.retrieve_all
    render :partial=>"new"
  end

  def index
    @activation_keys = ActivationKey.retrieve_by_org(working_org.key)
  end

  def edit
    render :partial => 'edit', :layout => "tupane_layout"
  end

  def update
    @activation_key.update_attributes(params[:activation_key])
    puts @activation_key.to_json()
    @activation_key.save!

    respond_to do |format|
      format.html {render :text => params[:activation_key].values.first}
      format.js
    end
  end

  def create
    @activation_key = ActivationKey.new("name" => params["name"])
    @activation_key.subscriptions = params[:checkgroup] ?
                                                        params[:checkgroup] : []
    @activation_key.owner= working_org

    saved, error_message = @activation_key.save
    if saved
      @activation_key = ActivationKey.retrieve(@activation_key.uuid)
      render :partial=>"common/list_item", :locals=>{:item=>@activation_key, :accessor=>"id",
                                                      :name =>@activation_key.name,
                                                      :columns=>['name', 'poolCount']}
    else
      Rails.logger.ap error_message
      errors error_message
      render :text => error_message, :status => :bad_request
    end
  end

  def destroy
    @activation_key.destroy
    redirect_to :action => 'index', :notice => N_("Activation Key '#{@activation_key.name}' was deleted.")
  end

  def find_activation_key
    @activation_key = ActivationKey.retrieve(params[:id])
    @organization = Organization.retrieve(@activation_key.owner["key"])
  end
end
