/**
 Copyright 2011 Red Hat, Inc.

 This software is licensed to you under the GNU General Public
 License as published by the Free Software Foundation; either version
 2 of the License (GPLv2) or (at your option) any later version.
 There is NO WARRANTY for this software, express or implied,
 including the implied warranties of MERCHANTABILITY,
 NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
 have received a copy of GPLv2 along with this software; if not, see
 http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.
*/

/*
 * A small javascript file needed to load things whenever a role is opened for editing
 *
 */
KT.roles = {};

KT.roles.permissionWidget = function(){
    var current_stage       = undefined,
    	mode				= 'create',
        next_button         = $('#next_button'),
        previous_button     = $('#previous_button'),
        done_button         = $('#save_permission_button'),
        all_types_button    = $('#all_types'),
        all_verbs_button    = $('#all_verbs'),
        all_tags_button     = $('#all_tags'),
        
        flow = {},
    
        init = function(){
            //previous_button.hide();
            //done_button.hide();
            //next_button.unbind('click').click(handleNext);
            //previous_button.unbind('click').click(handlePrevious);
            done_button.unbind('click').click(handleDone);
            //all_types_button.unbind('click').click(function(){ handleAllTypes(); });
            //all_verbs_button.unbind('click').click(function(){ handleAllVerbs(); });
            //all_tags_button.unbind('click').click(function(){ handleAllTags(); });
            current_stage = 'name';
        },
        reset = function(){
        	var item;
        	
            handleAllTypes(true);
            
            for( item in flow ){
                if( flow.hasOwnProperty(item) && item !== 'name' ){
                    flow[item].container.hide();
                }
            }
            
            //all_verbs_button.removeClass('selected');
            //all_verbs_button.html(i18n.all);
            //all_tags_button.removeClass('selected');
            //all_tags_button.html(i18n.all);
            //previous_button.hide();
            //next_button.show();
            //done_button.hide();
            //done_button.removeClass('disabled');
            //flow['verbs'].input.removeAttr('disabled');
            //flow['tags'].input.removeAttr('disabled');
            //current_stage = 'name';
            $('#add_permission_form')[0].reset();
            $('.validation_error').remove();
        },
        handleNext = function(){
            var next = flow[current_stage].next; 

            if( flow[current_stage].validate() ){
                flow[next].container.show();
                flow[next].actions();
                current_stage = next;   
            }
        },
        handlePrevious = function(){
            var previous = flow[current_stage].previous; 
            
            flow[current_stage].container.hide();
            flow[previous].actions();
            current_stage = previous;
        },
        handleDone = function(){
            if ( done_button.hasClass('disabled') ){
                    return false;
            }
            
            done_button.addClass('disabled');
            roleActions.savePermission(mode, 
            	function(){
                	current_stage = 'name';
                	reset();
                	done_button.removeClass('disabled');
            	},
            	function(){
            		done_button.removeClass('disabled');
            	});
        },
        set_types = function(current_organization){
            var types           = roles_breadcrumb[current_organization].permission_details,
                types_select    = flow['resource_type'].input,
                html            = "";
            
            types_select.empty();
            for( type in types ){
                if( types.hasOwnProperty(type) ){
                    if( type !== "all" ){
                        if( current_organization.split('_')[0] === 'organization' ){
                            if( !types[type].global ){
                                html += '<option value="' + type + '">' + types[type].name + '</option>';
                            }
                        } else {
                            html += '<option value="' + type + '">' + types[type].name + '</option>';
                        }
                    } else {
                        html += '<option class="hidden" value="all">All</option>';
                    }
                }
            }

            types_select.append(html);        	
        },
        set_verbs_and_tags = function(type, current_organization){
        	var i, length=0,
                verbs_select = flow['verbs'].input,
                tags_select = flow['tags'].input,
                verbs = roles_breadcrumb[current_organization].permission_details[type].verbs,
                tags = roles_breadcrumb[current_organization].permission_details[type].tags,
                html = '';
        
            length = verbs.length;
            verbs_select.empty();
            for( i=0; i < length; i+= 1){
                html += '<option value="' + verbs[i].name + '">' + verbs[i].display_name + "</option>";
            }
            verbs_select.append(html);
            
            html = '';
            flow['tags'].container.find('.info_text').remove();
            
            if( type !== 'organizations' && current_organization !== "global" ){
                length = tags.length;
                tags_select.empty();
                for( i=0; i < length; i+= 1){
                    html += '<option value="' + tags[i].name + '">' + tags[i].display_name + "</option>";
                }
                tags_select.append(html);
                tags_select.show();
                all_tags_button.show();
            } else {
            	tags_select.hide();
            	all_tags_button.hide();
            	flow['tags'].container.append('<span class="info_text" >' + i18n.no_tags_for_type + '</span>');
            }
        },
       	add_permission = function(options){
            var opening                 = options.opening,
                current_organization    = roleActions.getCurrentOrganization(),
                button                  = $('#add_permission');
            
            mode = 'create';
           //Headpin also only wants to be able to act on organizations 
            if( opening ){
                reset();
                button.children('span').html(i18n.close_add_permission);
                button.addClass("highlighted");
                
                if( current_organization === "global" ){
                    $('#permission_widget_header').html(i18n.add_header_global);
                } else {
                    $('#permission_widget_header').html(i18n.add_header_org + ' ' + roles_breadcrumb[current_organization].name);
                }
            } else {
                button.children('span').html(i18n.add_permission);
                button.removeClass("highlighted");
            }
            
            return options;
        },
        edit_permission = function(options){
        	var permission 				= roles_breadcrumb[options.id],
        		opening 			 	= options.opening,
                current_organization 	= roleActions.getCurrentOrganization(),
        		button 					= $('#edit_permission'),
        		i = 0, length = 0, values =[];
        	
        	mode = 'update';
        	$('#step_1').hide();
        	$('#step_2').hide();
        	$('#step_3').hide();
        	$('#step_4').hide();
        	
            if( opening ){
                reset();
                button.children('span').html(i18n.close_edit_permission);
                button.addClass("highlighted");
                set_types(current_organization);

				for( item in flow ){
					flow[item].container.show();
				}

				flow['resource_type'].input.val(permission.type);
				flow['name'].input.val(permission.name);
				$('#description').val(permission.description);
                
                flow['resource_type'].input.unbind('change').change(function(event){
                    set_verbs_and_tags(event.currentTarget.value, current_organization);
                    
                    if( event.currentTarget.value === 'all' ){
                    	handleAllTypes();
                    }

                    if( all_verbs_button.hasClass('selected') ){
                        handleAllVerbs();
                    }
                    if( all_tags_button.hasClass('selected') ){
                        handleAllTags();
                    }
                }).change();

				if( permission.verbs === 'all' ){
					handleAllVerbs(false);
				} else {
					length = permission.verbs.length;
					for( i=0; i < length; i += 1){
						values.push(permission.verbs[i].name);
					}
					flow['verbs'].input.val(values);
				}
				
				if( permission.tags === 'all'){
					handleAllTags(false);
				} else {
					length = permission.tags.length;
					values = [];
					for( i=0; i < length; i += 1){
						values.push(permission.tags[i].name);
					}
					flow['tags'].input.val(values);	
				}

				current_stage = 'tags';
				flow['tags'].actions();

                $('#permission_widget_header').html(i18n.edit_permission_header + ' ' + roles_breadcrumb[current_organization].name + ' - ' + permission.name);
            } else {
                button.children('span').html(i18n.edit_permission);
                button.removeClass("highlighted");
            }
        	
        	return options;
        },
        handleAllTypes = function(selected){
            selected = selected || all_types_button.hasClass('selected');
            
        },
        handleAllVerbs = function(selected){
            selected = selected || all_verbs_button.hasClass('selected');
            
            if( !selected ){
                flow['verbs'].input.attr('disabled', 'disabled');
                all_verbs_button.html(i18n.cancel);
                all_verbs_button.addClass('selected');
            } else {
                flow['verbs'].input.removeAttr('disabled');
                all_verbs_button.html(i18n.all);
                all_verbs_button.removeClass('selected');
            }
        },
        handleAllTags = function(selected){
            selected = selected || all_tags_button.hasClass('selected');
            
            if( !selected ){
                flow['tags'].input.attr('disabled', 'disabled');
                all_tags_button.html(i18n.cancel);
                all_tags_button.addClass('selected');
            } else {
                flow['tags'].input.removeAttr('disabled');
                all_tags_button.html(i18n.all);
                all_tags_button.removeClass('selected');
            }
        };
        
    return {
        add_permission	:  add_permission,
        edit_permission	:  edit_permission,
        init            :  init
    };
    
};

var roleActions = (function($){
    var current_crumb = undefined,
        current_organization = undefined,

        role_edit = function(options){
            var name_box        = $('.edit_name_text'),
                edit_button     = $('#edit_role > span'),
                description     = $('.edit_description'),    
                after_function  = undefined,
                nameBreadcrumb  = $('.tree_breadcrumb'),
                opening         = options.opening,
                
                setup_edit = function() {
                    var url = KT.common.rootURL() + "admin/roles/" + $('#role_id').val(),
                        name_box = $('.edit_name_text'),
                        description = $('.edit_description'),
                        common = {
                            method      : 'PUT',
                            cancel      :  i18n.cancel,
                            submit      :  i18n.save,
                            indicator   :  i18n.saving,
                            tooltip     :  i18n.clickToEdit,
                            placeholder :  i18n.clickToEdit,
                            submitdata  :  {authenticity_token: AUTH_TOKEN},
                            onerror     :  function(settings, original, xhr) {
                                original.reset();
                            }
                        };

                    name_box.each(function() {
                        var settings = {
                                type        :  'text',
                                width       :  270,
                                name        :  $(this).attr('name'),
                                onsuccess   :  function(data) {
                                      var parsed = $.parseJSON(data);
                                      roles_breadcrumb.roles.name = parsed.name;
                                      $('#list #role_' + $('#role_id').val() + ' .column_1').html(parsed.name);
                                      $('.edit_name_text').html(parsed.name);
                                      $('#roles').html(parsed.name + " \u2002\u00BB\u2002");
                                }
                        };
                        $(this).editable( url, $.extend(settings, common));
                    });
            
                   description.each(function() {
                        var settings = {
                                type        :  'textarea',
                                name        :  $(this).attr('name'),
                                rows        :  5,
                                cols        :  30,
                                onsuccess   :  function(data) {
                                      var parsed = $.parseJSON(data);
                                      $('.edit_description').html(parsed.description);
                                }
                        };
                        $(this).editable( url, $.extend(settings, common));
                    });
                };
    
            if ( opening ) {
                edit_button.html(i18n.close_role_details);
                edit_button.parent().addClass("highlighted");
                options['after_function'] = setup_edit;
            }
            else {
                edit_button.html(i18n.edit_role_details);
                edit_button.parent().removeClass("highlighted");
            }
            
            return options;
        },
        setCurrentCrumb = function(hash_id){
            current_crumb = hash_id;
        },
        getCurrentOrganization = function(){
            return current_organization;  
        },
        setCurrentOrganization = function(hash_id){
            var split = hash_id.split('_');
            
            if( split[0] === 'organization' || split[0] === 'global' ){
                current_organization = hash_id;
                getPermissionDetails();
            } else if( split[1] === 'global' ) {
                current_organization = 'global';
                getPermissionDetails();
            } else if( split[0] === 'permission' ) {
                current_organization = 'organization_' + split[1];
                getPermissionDetails();
            } else {
                current_organization = hash_id;
            }
        },
        getPermissionDetails = function(){

        },
        savePermission = function(mode, successCallback, errorCallback){
            var org_id = current_crumb.split('_')[1],
                form = $('#add_permission_form'),
                to_submit = form;
            
            if( current_organization !== "global" ){
                to_submit.find("#organization_id").val(org_id);
            }
            
            if( to_submit instanceof Array ){
                to_submit = $.param(to_submit);
            } else {
                to_submit = to_submit.serialize();
            }
            
            if( mode === 'create' ){
	            $.ajax({
	               type     : "PUT",
                   url      : $('#save_permission_button').attr('data-url'),
	               cache    : false,
	               data     : to_submit,
	               dataType : 'json',
	               success  : function(data){
	                   //$.extend(roles_breadcrumb, data);
	                   KT.roles.tree.rerender_content();
	                   form[0].reset();
	                   roles_breadcrumb[current_organization].count += 1
	
	                   //if( data.type === "all" ){
	                   //    roles_breadcrumb[current_organization].full_access = true
	                  // }
	                   
	                   successCallback();
	               },
	               error	: function(){
	               		errorCallback();	
	               }
	            });
            } else if( mode === 'update' ){
	            $.ajax({
	               type     : "POST",
	               url      : KT.common.rootURL() + "admin/roles/" + $('#role_id').val() + "/permission/" + current_crumb.split('_')[2] + "/update_permission/",
	               cache    : false,
	               data     : to_submit,
	               dataType : 'json',
	               success  : function(data){
	                   roles_breadcrumb[current_crumb] = data[current_crumb];
	                   KT.roles.tree.rerender_content();
	                   KT.roles.tree.rerender_breadcrumb();
	                   form[0].reset();
	
	                   if( data.type === "all" ){
	                       roles_breadcrumb[current_organization].full_access = true
	                   }
	                   
	                   successCallback();
	               },
	               error	: function(){
	               		errorCallback();
	               }
	            });
            }
        },
        remove_permission = function(element){
            var id = element.attr('data-id');

            element.html(i18n.removing);
            
            $.ajax({
               type     : "DELETE",
               url      : KT.common.rootURL() + "admin/roles/" + $('#role_id').val() + "/permission/" + id.split('_')[2] + "/destroy_permission/",
               cache    : false,
               dataType : 'json',
               success  : function(data){
                    if( roles_breadcrumb[id].type === "all" ){
	                    delete roles_breadcrumb[id];
                    	roles_breadcrumb[current_organization].full_access = false;
                    	
                    	for( item in roles_breadcrumb ){
                    		if( roles_breadcrumb.hasOwnProperty(item) ){
                    			if( item.split('_')[0] === 'permission' && item.split('_')[1] === id.split('_')[1] && roles_breadcrumb[item].type === 'all'){
                    				roles_breadcrumb[current_organization].full_access = true;
                    			}
                    		}
                    	}
                    } else {
                		delete roles_breadcrumb[id];
                	}
                    roles_breadcrumb[current_organization].count -= 1;
                    KT.roles.tree.rerender_content();
               },
               error 	: function(){
               		element.removeClass('disabled');
               }
            });
        },
        edit_user = function(element, adding){
            var submit_data = { update_users : { adding : adding, user_id : element.attr('data-id').split('_')[1] }};

            if( adding ){
                element.html(i18n.adding);
            } else {
                element.html(i18n.removing);
            }
            $.ajax({
               type     : "PUT",
               url      : KT.common.rootURL() + "admin/roles/" + $('#role_id').val(),
               cache    : false,
               data     : $.param(submit_data),
               dataType : 'json',
               success  : function(data){
                    if( adding ){
                        roles_breadcrumb[element.attr('data-id')].has_role = true;
                    } else {
                        roles_breadcrumb[element.attr('data-id')].has_role = false;
                    }
                    KT.roles.tree.rerender_content();
               },
               error 	: function(){
               		element.removeClass('disabled');
               }
            });
        },
        handleContentAddRemove = function(element){
        	element.addClass('disabled');
        	
            if( element.attr('data-type') === 'permission' ){
                if( element.hasClass('remove_permission') ){
                    remove_permission(element);
                }
            } else if( element.attr('data-type') === 'user'){
                if( element.hasClass('add_user') ){
                    edit_user(element, true);
                } else if( element.hasClass('remove_user') ){
                    edit_user(element, false);
                }
            }
        },
        removeRole = function(button){
            button.addClass('disabled');
            $.ajax({
                type: "DELETE",
                url: button.attr('data-url'),
                cache: false,
                success: function(data){
                    // Generally a bad idea - trusting implicility the data being returned from the server
                    // This conforms with how other 'removes' on the site work - relying on a partial template
                    // to render and return the proper actions for a delete
                    eval(data);
                }
            });
        };

    return {
        getPermissionDetails    :  getPermissionDetails,
        setCurrentCrumb         :  setCurrentCrumb,
        savePermission          :  savePermission,
        handleContentAddRemove  :  handleContentAddRemove,
        setCurrentOrganization  :  setCurrentOrganization,
        getCurrentOrganization  :  getCurrentOrganization,
        removeRole              :  removeRole,
        role_edit               :  role_edit
    };
    
})(jQuery);

var templateLibrary = (function($){
    var listItem = function(id, name, count, notation, no_slide){
            var html ='';
            
            if( no_slide ){
                html += '<li class="no_slide"><div id="' + id + '">'; 
            } else {
                html += '<li class="slide_link"><div class="simple_link link_details" id="' + id + '">';
            }
   
            html += '<span class="sort_attr">'+ name;
   
            if( notation !== undefined && notation !== null && notation !== false ){
                html += ' (' + notation + ') ';
            }
   
            if( count !== undefined && count !== null && count !== false ){
                html += ' (' + count + ')';
            }
            
            html += '</span></div></li>';
            
            return html;
        },
        list = function(items, type, options){
            var html = '<ul class="filterable">',
                options = options ? options : {};
            for( item in items){
                if( items.hasOwnProperty(item) ){
                    if( item.split("_")[0] === type ){
                        html += listItem(item, items[item].name, false, false, options.no_slide);
                    }
                }
            }
            html += '</ul>';
            return html;
        },
        organizationsList = function(items, type, options){
            var html = '<ul class="filterable">',
                options = options ? options : {},
                full_access = false;
            
            //html += listItem('global', items['global'].name, items['global'].count, false);
            
            for( item in items){
                if( items.hasOwnProperty(item) ){
                    if( item.split("_")[0] === type ){
                        full_access = items[item].full_access ? i18n.full_access : false;
                        html += listItem(item, items[item].name, items[item].count, full_access, options.no_slide);
                    }
                }
            }
            html += '</ul>';
            return html;
        },
        permissionsList = function(permissions, organization_id, options){
            var html = '<ul class="filterable">',
            	count = 0;
            
            for( item in permissions){
                if( permissions.hasOwnProperty(item) ){
                    if( item.split("_")[0] === "permission" && permissions[item].organization === 'organization_' + organization_id ){
                        html += permissionsListItem(item, permissions[item].name, options.show_button);
                        count += 1;
                    }
                }
            }
            if( count === 0 ){
            	html += '<li class="no_slide no_hover">' + i18n.no_permissions + '</li>';
            }
            html += '</ul>';
            return html;
        },
        permissionsListItem = function(permission_id, name, showButton) {
            var anchor = "";

            if ( showButton ) {
                anchor = '<a ' + 'class="fr content_add_remove remove_permission st_button"'
                                + 'data-type="permission" data-id="' + permission_id + '">';
                            anchor += i18n.remove + "</a>";
            }
            
            return '<li class="slide_link">' + anchor + '<div class="simple_link link_details" id="' + permission_id + '"><span class="sort_attr">'  + name + '</span></div></li>';
        },
        permissionItem = function(permission){
            var i = 0, length = 0,
                html = '<div class="permission_detail">';
            
            html += '<div class="permission_detail_container"><label class="grid_3 ra">ID: </label><span>' + permission.cust_id + '</span></div>';
            html += '<div class="permission_detail_container"><label class="grid_3 ra">Permission For: </label><span>' + permission.type_name + '</span></div>';
            
            html += '</ul></div></div>';

            return html;
        },
        usersListItem = function(user_id, name, has_role, no_slide, showButton) {
            var anchor = "",
                html = no_slide ? '<li class="no_slide">' : '<li class="slide_link">';

            if ( showButton ) {
                anchor = '<a ' + 'class="fr content_add_remove ';
                anchor += has_role ? 'remove_user' : 'add_user';
                anchor += ' st_button" data-type="user" data-id="' + user_id + '">';
                anchor += has_role ? (i18n.remove + "</a>") : (i18n.add + "</a>");
            } else {
                anchor = "<div class=\"fr st_button\">";
                anchor += has_role ? (i18n.rule_applied + "</div>") : (i18n.rule_not_applied + "</div>");                
            }
            
            html += anchor + '<div class="simple_link ';
            html += no_slide ? "" : "link_details";
            html += '"><span class="sort_attr">'  + name + '</span></div></li>';
            
            return html;
        },
        usersList = function(users, options){
            var html = '<ul class="filterable">',
                user = undefined;
            
            for( item in users){
                if( users.hasOwnProperty(item) ){
                    user = item.split("_");
                    if( user[0] === "user" ){
                        html += usersListItem(item, users[item].name, users[item].has_role, options.no_slide, options.show_button);
                    }
                }
            }
            html += '</ul>';
            return html;
        },
        globalsList = function(globals, options){
            var html = '<ul class="filterable">',
            	count = 0;
            
            for( item in globals ){
                if( globals.hasOwnProperty(item) ){
                    if( item.split("_")[0] === "permission" && item.split("_")[1] === 'global' ){
                        html += permissionsListItem(item, globals[item].name, options.show_button);
                        count += 1;
                    }
                }
            }
            if( count === 0 ){
            	html += '<li class="no_slide no_hover">' + i18n.no_global_permissions + '</li>';
            }
            html += '</ul>';
            return html;
        };
    
    return {
        list                :    list,
        organizationsList   :    organizationsList,
        permissionsList     :    permissionsList,
        usersList           :    usersList,
        globalsList         :    globalsList,
        permissionItem      :    permissionItem
    }
}(jQuery));

var rolesRenderer = (function($){
    var render = function(hash, render_cb){
            var options = {};
            
            if( hash === 'role_permissions' ){
                render_cb(templateLibrary.organizationsList(roles_breadcrumb, 'organization'));
            } else if( hash === 'roles' ) {
                render_cb(templateLibrary.list(roles_breadcrumb, 'role'));
            } else if( hash === 'role_users' ){
                if (permissions.create_roles || permissions.update_roles) {
                    options.show_button = true;
                }
                
                options.no_slide = true;
                render_cb(templateLibrary.usersList(roles_breadcrumb, options));
            } else if( hash === 'global' ) {
                if (permissions.create_roles || permissions.update_roles) {
                    options.show_button = true;
                }
                
                options.no_slide = false;
                render_cb(templateLibrary.globalsList(roles_breadcrumb, options));
            } else {
                var split = hash.split("_"),
                    page = split[0],
                    organization_id = split[1];

                render_cb(getContent(page, hash, organization_id));
            }
        },
        getContent = function(key, hash, organization_id){
            var options = {};
            
            if( key === 'organization' ){
                if (permissions.create_roles || permissions.update_roles) {
                    options.show_button = true;
                }

                return templateLibrary.permissionsList(roles_breadcrumb, organization_id, options);
            } else if( key === 'permission' ){
                return templateLibrary.permissionItem(roles_breadcrumb[hash]);
            }
        },
        sort = function(hash_id) {
            $(".will_have_content").find("li").sortElements(function(a,b){
                    var a_html = $(a).find(".sort_attr").html();
                    var b_html = $(b).find(".sort_attr").html();
                    if (a_html && b_html ) {
                        return  a_html.toUpperCase() >
                                b_html.toUpperCase() ? 1 : -1;
                    }
            });
                
            if( hash_id === "role_permissions" ){
                $('#global').parent().prependTo($(".will_have_content ul"));  
            }
        },
        setTreeHeight = function(){
            var height = $('.left').height(),
                panel_main = $('#panel_main');
                
            panel_main.find('.sliding_list').css({ 'height' : height - 60 });
            panel_main.find('.slider').css({ 'height' : height - 60 });
            panel_main.height(height);
            panel_main.find('.jspPage').height(height);
        },
        setSizing = function(){
            var panel = $('.panel-custom'),
                width = panel.width();
            
            width -= 4;
            panel.find('.sliding_container').width(width);
            panel.find('.breadcrumb_search').width(width);
            panel.find('.slider').width(width);
            panel.find('.sliding_list').width(width * 2);
            panel.find('.slide_up_container').width(width);
        },
        init = function(){
            var left_panel = $('.left');
            
            left_panel.resize(function(){
                setSizing();
            });
            left_panel.trigger('resize');
        },
        setSummary = function(hash_id){
            var summary = $('#roles_status');
             
            if( hash_id === 'roles' ){
                if (permissions.create_roles || permissions.update_roles) {
                    summary.html(i18n.roles_summary);
                } else {
                    summary.html(i18n.roles_summary_readonly);
                }
            } else if( hash_id === 'role_users' ) {
                if (permissions.create_roles || permissions.update_roles) {
                    summary.html(i18n.users_summary);
                } else {
                    summary.html(i18n.users_summary_readonly);
                }

            } else if ( hash_id === 'role_permissions' ) {
                if (permissions.create_roles || permissions.update_roles) {
                    summary.html(i18n.role_permissions_summary);
                } else {
                    summary.html(i18n.role_permissions_summary_readonly);
                }
            } else if ( hash_id === 'global' || hash_id.match(/organization?/g) ){
                if (permissions.create_roles || permissions.update_roles) {
                    summary.html(i18n.permissions_summary);
                } else {
                    summary.html(i18n.permissions_summary_readonly);
                }
            } else if ( hash_id.match(/permission?/g) ){
            	if (permissions.create_roles || permissions.update_roles) {
                    summary.html(i18n.permission_detail_summary);
                } else {
                    summary.html(i18n.permission_detail_readonly);
                }
            }
        },
        handleButtons = function(hash_id){
            var type = hash_id.split('_')[0],
            	add_permission_button = $('#add_permission'),
            	edit_permission_button = $('#edit_permission');

            if( type === 'organization' || type === 'permission' || type === 'global' ){
                add_permission_button.removeClass('disabled');
                roleActions.setCurrentOrganization(hash_id);
            } else {
                add_permission_button.addClass('disabled');
                roleActions.setCurrentOrganization('');
            }
            
            if( type === 'permission' ){
            	edit_permission_button.removeClass('disabled');
            } else if( !edit_permission_button.hasClass('disabled') ) {
            	edit_permission_button.addClass('disabled');
            }
        };
    
    return {
        init            :   init,
        render          :   render,
        sort            :   sort,
        setTreeHeight   :   setTreeHeight,
        setSummary      :   setSummary,
        handleButtons   :   handleButtons
    }
    
}(jQuery));

var pageActions = (function($){
    var toggle_list = {
            'role_edit'	:  { container 	: 'role_edit',
            				 setup_fn 	: roleActions.role_edit }
        },
    
        registerEvents = function(){
        	var action_bar = KT.roles.actionBar;
        	
            $('#edit_role').live('click', function() {
                if ($(this).hasClass('disabled')){
                    return false;
                }
                action_bar.toggle('role_edit');
            });
            
            $('#add_permission').live('click', function() {
                if ( $(this).hasClass('disabled') ){
                    return false;
                }
                action_bar.toggle('add_permission', { add : true });
            });
            
            $('#edit_permission').live('click', function() {
                if ( $(this).hasClass('disabled') ){
                    return false;
                }
                action_bar.toggle('edit_permission', 
                	{ edit : true, id : KT.roles.tree.get_current_crumb() }
               	);
            });            
            
            $('.content_add_remove').live('click', function(){
            	if( $(this).hasClass('disabled') ){
            		return false;
            	}
                roleActions.handleContentAddRemove($(this));
            });
            
            
            $('#remove_role').live('click', function(){
                var button = $(this);
                KT.common.customConfirm(button.attr('data-confirm-text'), function(){
                    roleActions.removeRole(button);
                });         
            });
            
            KT.panel.set_contract_cb = function(name){
                $.bbq.removeState("role_edit");
                $('#panel').removeClass('panel-custom');
                action_bar.reset();
            };
                    
            KT.panel.set_switch_content_cb = function(){
                $.bbq.removeState("role_edit");
                $('#panel').removeClass('panel-custom');
                action_bar.reset();
            };
        };
    
    return {
        registerEvents  :  registerEvents,
        toggle_list     :  toggle_list
    };
    
})(jQuery);

$(document).ready(function() {
  
    KT.roles.actionBar = sliding_tree.ActionBar(pageActions.toggle_list);
  
    pageActions.registerEvents();
    
    $('.left').resizable('destroy');    
    
});
