//Create role functions
function createNewRole(){
    role.create($('#role_name_field').val(), 
          successCreate, errorAlert);
}

function successCreate() {
  //alert("Created!");
}

function errorAlert(request) {
  //  alert(request.responseText);
}

function update_verbs_and_scopes() {
  var verb_box = $(this).closest("div[id^=permission_]").find('select[data_type=verbs]');
	var scope_box = $(this).closest("div[id^=permission_]").find('select[data_type=tags]');
	role.get_verbs_and_scopes($('option:selected',$(this)).val(),
			function(json, status, xhr) {
				//remove all the existing options
				$('option',verb_box).remove();
				$('option',scope_box).remove();
				//add new options
				$.each(json.verbs, function(index, name) {
					var optionName = name;
					var optionValue = name;
					$('<option/>').attr('value',optionValue).text(optionName).appendTo(verb_box);
				});
				$.each(json.scopes, function(index, name) {
					var optionName = name;
					var optionValue = name;
					$('<option/>').attr('value',optionValue).text(optionName).appendTo(scope_box);
				});

			},
			errorAlert);
}


function toggle_available() {
		var type = $(this).attr("data_type");
	  select_box = $(this).closest("div[id^=permission_]").find('select[data_type='+type + ']');
	  if ($(this).val() == "true") {
	    select_box.attr("disabled", true);
	  }
	  else {
	    select_box.removeAttr("disabled");
	  }
}

$(document).ready(function() {

    $('#save_role_button').live('click',createNewRole);
    $('div[id^="closed_"]').live('click', showPermission);
    $('#add_permission').live('click',add_permission);

    $('div[id^=cancel_button_]').live('click',cancel_permission);
    $('div[id=delete_permission]').live('click',remove_permission);

	$('input[data_type=tags]:radio:checked').live("change", toggle_available);
	$('input[data_type=verbs]:radio:checked').live("change", toggle_available);

	$('select[data_type=types]').live("change", update_verbs_and_scopes);

	$('div[id=save_permission]').live("click", form_submit);
});


//Re-creates new buttson that might have been added
function reset_buttons() {
    $('#add_permission').button();
    $('#save_role_button').button();
    $('div[id^=cancel_button_]').button();
	$('div[id=save_permission]').button();
    $('input[data_type=tags]:radio:checked').trigger("change");
    $('input[data_type=verbs]:radio:checked').trigger("change");
}


function showPermission(event) {
	$(this).hide();
	$(this).siblings("div[id^=opened_]").show();
}


function permissionRemoved() {
  //alert("Permission Removed!");
}

function remove_permission() {
  var role_id = $(this).attr("data_role_id");
  var perm_id = $(this).attr("data_perm_id");
  role.remove_permission(role_id, perm_id, permissionRemoved, errorAlert);
  $(this).closest(".permission").remove();
  $("#permissions :hidden[value=" + perm_id+ "]").remove();

}

function add_permission() {
  var button = $(this);
  role.get_new(button.attr("data_id"), button.attr("data_url"),
      function(data) {
	$(data).insertBefore("#add_permission");
		reset_buttons();
	  });
}



function cancel_permission() {
	var button = $(this);
	var parent = button.parents("div[id^=permission_]");
	if(button.attr("data_is_new") == "true"){
		parent.remove();
	}
	else {
		role.get_existing(button.attr("data_role_id"), button.attr("data_perm_id"), button.attr("data_url"),
		    function(data) {  //Success function
			 parent.replaceWith(data);
			 reset_buttons()
		    });
	}
}


function form_submit (event){
	// we want to submit the form using Ajax (prevent page refresh)
	event.preventDefault();
	// store reference to the form
	var form = $(this).closest("form");
	// grab the url from the form element
	var url = form.attr('action');
	var method = form.attr('method');
	// prepare the form data to send
	var dataToSend = form.serialize();

	var on_success = function(dataReceived){
		var perm_div = form.closest("div[id^=permission_]");
		perm_div.replaceWith(dataReceived);
		reset_buttons();
	};
	role.create_or_update_permission( method, url, dataToSend, on_success, errorAlert);
}

