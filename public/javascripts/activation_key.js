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

$(document).ready(function() {

//    KT.panel.set_expand_cb(function() {
//      KT.env_select_scroll().bind();
 //   });

   $('#new_activation_key').live('submit', function(e) {
      e.preventDefault();
      var button = $(this).find('input[type|="submit"]');
       button.attr("disabled","disabled");
      $(this).ajaxSubmit({
          success: function(data) {
            list.add(data);
            KT.panel.closePanel($('#panel'));
            KT.panel.select_item(list.last_child().attr("id"));
          },
          error: function(e) {
            button.removeAttr('disabled');
          }});
   });

});
