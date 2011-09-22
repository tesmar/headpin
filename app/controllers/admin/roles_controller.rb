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

class Admin::RolesController < ApplicationController
  include AutoCompleteSearch
  include BreadcrumbHelper
  include BreadcrumbHelper::RolesBreadcrumbs
  navigation :roles
  before_filter :require_user
  before_filter :require_admin
  respond_to :html, :js

  def section_id
     'admin'
   end

  def index
    @roles = Role.retrieve_all
  end

  def new
    @role = Role.new
    render :partial=>"new", :layout => "tupane_layout", :locals=>{:role=>@role}
  end

  def edit
    @role = Role.retrieve(params[:id])
    render :partial=>"edit", :layout => "tupane_layout", :locals=>{:role=>@role }
  end

  def create
    @role = Role.new(params[:role])
    new_role = @role.save
    if new_role
      notice(new_role.name + " " + _("Role created."))
      render :partial=>"common/list_item", :locals=>{:item=>new_role, :name => "role", :accessor=>"id", :columns=>["name"]}
    else
      errors "", {:list_items => new_role.errors.to_a}
      render :json=>new_role.errors, :status=>:bad_request
    end
  end

  def update
    @role = Role.retrieve(params[:id])
    return if @role.name == "admin"

    if params[:update_users]
      user = User.retrieve(params[:update_users][:user_id])
      if params[:update_users][:adding] == "true"
        @role.add_user(user)
      else
        @role.remove_user(user)
      end
      params[:update_users][:user_id] = user.id
      notice _("Role updated.")
      render :json => params[:update_users]
    elsif @role.update(params[:role])
      notice _("Role updated.")
      render :json=>params[:role]
    else
      errors "", {:list_items => @role.errors.to_a}
      respond_to do |format|
        format.html { render :partial => "layouts/notification", :status => :bad_request, :content_type => 'text/html' and return}
        format.js { render :partial => "layouts/notification", :status => :bad_request, :content_type => 'text/html' and return}
      end
    end
  end

  def destroy
    @id = params[:id]
    @role = Role.retrieve(@id)
    begin
      #remove the user
      destroyed = @role.destroy
      if destroyed
        notice _("Role '#{@role.name}' was deleted.")
        #render and do the removal in one swoop!
        render :partial => "common/list_remove", :locals => {:id => @id, :name => "role"}
      end
    rescue Exception => error
    Rails.logger.ap error.backtrace
      errors error.to_s
      render :text=> error.to_s, :status=>:bad_request and return
    end
  end

  def update_permission
    @permission = Permission.retrieve(params[:permission_id])
    @permission.update_attributes(params[:permission])
    notice _("Permission '#{@permission.name}' updated.")
    render :partial => "permission", :locals =>{:perm => @permission, :role=>@role, :data_new=> false}
  end

  def create_permission
    new_params = {:role => @role}
    type_name = params[:permission][:resource_type_attributes][:name]

    if type_name == "all"
      new_params[:all_tags] = true
      new_params[:all_verbs] = true
    end

    new_params[:resource_type] = ResourceType.find_or_create_by_name(:name=>type_name)
    new_params.merge! params[:permission]

    begin
      @perm = Permission.create! new_params
      to_return = { :type => @perm.resource_type.name }
      add_permission_bc(to_return, @perm, false)
      notice _("Permission '#{@perm.name}' created.")
      render :json => to_return
    rescue Exception => error
      errors error
      render :json=>@role.errors, :status=>:bad_request
    end
  end

  def show_permission
    if params[:perm_id].nil?
      permission = Permission.new(:role=> @role, :resource_type => ResourceType.new)
    else
      permission = Permission.retrieve(params[:perm_id])
    end
    render :partial=>"permission", :locals=>{:perm=>permission, :role=>@role, :data_new=>permission.new_record?}
  end

  def destroy_permission
    permission = Permission.retrieve(params[:permission_id])
    permission.destroy
    notice _("Permission '#{permission.name}' removed.")
    render :json => params[:permission_id]
  end

  private
  def find_role
    @role =  Role.retrieve(params[:role_id]) if params.has_key? :role_id
    @role =  Role.retrieve(params[:id]) unless params.has_key? :role_id
  rescue Exception => error
    render :text=>errors.to_s, :status=>:bad_request and return false
  end

end
