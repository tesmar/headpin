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

//#  $('.panelform').live('submit', function(e) {
//    e.preventDefault();
 //   $(this).ajaxSubmit(upload_options);
 // });

/*
 * A small javascript file needed to load system subscription related stuff
 *
 */

var systems_page = (function() {
  return {
    env_change : function(env_id, element) {
      var url = element.attr("data-url");
      window.location = url;
    },
    create_system : function(data) {
        var button = data.find('input[type|="submit"]');
        button.attr("disabled","disabled");
        data.ajaxSubmit({
            success: function(data) {
                list.add(data);
                KT.panel.closePanel($('#panel'));
                KT.panel.select_item(list.last_child().attr("id"));
            },
            error: function(e) {
                button.removeAttr('disabled');
            }
        });
    },
    delete_system : function(data) {
        var answer = confirm(data.attr('data-confirm-text'));
        if (answer) {
            $.ajax({
                type: "DELETE",
                url: data.attr('data-url'),
                cache: false,
                success: function() {
                    panel.closeSubPanel($('#subpanel'));
                    panel.closePanel($('#panel'));
                    list.remove(data.attr("data-id").replace(/ /g, '_'));
                }
            });
        }
    }
  }
})();

// Subscription value fields can either be a spinner or just a plain label (with hidden field).
// Only subscriptions that allow multiple entitlements are displayed with a spinner; others can
// only have a value of zero or one.
//
// Unsubscribe is a hidden field (w/ a class of ui-nonspinner) since the value is never adjustable.
KT.subs = function() {
    var unsubSetup = function(){
        var unsubform = $('#unsubscribe');
        var unsubbutton = $('#unsub_submit');
        var fakeunsubbutton = $('#fake_unsub_submit');
        var unsubcheckboxes = $('#unsubscribe input[type="checkbox"]');
        var total = unsubcheckboxes.length;
        var checked = 0;
        unsubbutton.hide();
        unsubcheckboxes.each(function(){
            $(this).change(function(){
                if($(this).is(":checked")){
                    checked++;
                    $(this).parent().parent().parent().find(".ui-nonspinner").val(1);
                    if(!(unsubbutton.is(":visible"))){
                        fakeunsubbutton.fadeOut("fast", function(){unsubbutton.fadeIn()});
                    }
                }else{
                    checked--;
                    $(this).parent().parent().parent().find(".ui-nonspinner").val(0);
                    if((unsubbutton.is(":visible")) && checked == 0){
                        unsubbutton.fadeOut("fast", function(){fakeunsubbutton.fadeIn()});
                    }
                }
            });
        });
        $("#Unsubscribe_subs").treeTable({
          expandable: true,
          initialState: "collapsed",
          clickableNodeNames: true,
          onNodeShow: function(){$.sparkline_display_visible()}  	
        });
    }, subSetup = function(){
        var subform = $('#subscribe');
        var subbutton = $('#sub_submit');
        var fakesubbutton = $('#fake_sub_submit');
        var subcheckboxes = $('#subscribe input[type="checkbox"]');
        var total = subcheckboxes.length;
        var checked = 0;
        var spinner, of_string;
        subbutton.hide();

        subcheckboxes.each(function(){
            $(this).change(function(){
                if($(this).is(":checked")){
                    checked++;
                    spinner = $(this).parent().parent().parent().find(".ui-spinner");
                    if (spinner.length > 0) {
                        spinner.spinner("increment");
                    } else {
                        $(this).parent().parent().parent().find(".ui-nonspinner").val(1);
                        spinner = $(this).parent().parent().parent().find(".ui-nonspinner-label")[0];
                        of_string = "1" + spinner.innerHTML.substr(1);
                        spinner.innerHTML = of_string;
                    }
                    if(!(subbutton.is(":visible"))){
                        fakesubbutton.fadeOut("fast", function(){subbutton.fadeIn()});
                    }
                }else{
                    checked--;
                    spinner = $(this).parent().parent().parent().find(".ui-spinner");
                    if (spinner.length > 0) {
                        spinner.spinner("decrement");
                    } else {
                        $(this).parent().parent().parent().find(".ui-nonspinner").val(0);
                        spinner = $(this).parent().parent().parent().find(".ui-nonspinner-label")[0];
                        of_string = "0" + spinner.innerHTML.substr(1);
                        spinner.innerHTML = of_string;
                    }
                    if((subbutton.is(":visible")) && checked == 0){
                        subbutton.fadeOut("fast", function(){fakesubbutton.fadeIn()});
                    }
                }
            });
        });
        $("#Subscribe_subs").treeTable({
          expandable: true,
          initialState: "collapsed",
          clickableNodeNames: true,
          onNodeShow: function(){$.sparkline_display_visible()}  	
        });
    }, spinnerSetup = function(){
        setTimeout("$('.ui-spinner').spinner()",1000);
    };
    return {
        unsubSetup: unsubSetup,
        subSetup: subSetup,
        spinnerSetup: spinnerSetup
    }
}();

$(document).ready(function() {
  $('#update_subscriptions').live('submit', function(e) {
     e.preventDefault();
     var button = $(this).find('input[type|="submit"]');
      button.attr("disabled","disabled");
     $(this).ajaxSubmit({
         success: function(data) {
               button.removeAttr('disabled');
               notices.checkNotices();
         }, error: function(e) {
               button.removeAttr('disabled');
               notices.checkNotices();
         }});
  });
  $('#new_system_form').live('submit', function(e) {
      e.preventDefault();
      systems_page.create_system($(this));
  });
  $('#systems_remove_form').live('submit', function(e) {
      e.preventDefault();
      systems_page.delete_system($(this));
  });

  // check if we are viewing systems by environment 
  if (window.env_select !== undefined) {
    env_select.click_callback = systems_page.env_change;
  }
});

