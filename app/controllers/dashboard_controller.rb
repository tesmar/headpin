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

class DashboardController < ApplicationController
  navigation :dashboard

  def section_id
    'dashboard'
  end

  def index
    @candlepin_up = true

    require_user
    require_org
    if !working_org
      @candlepin_up = false
      @candlepin_error_message = _("Unable to properly connect to the Entitlement Server")
    end
  end
end
