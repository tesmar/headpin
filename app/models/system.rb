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

require 'json'

class System < Base
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  # Candlepin calls this resource a consumer:
  self.element_name = "consumer"

  # Candlepin API expects an owner key as the ID:
  self.primary_key = :uuid

  def bind(pool_id)
    # TODO: hardcoded app prefix
    path = "/candlepin/consumers/#{uuid}/entitlements?pool=#{pool_id}"
    results = connection.post(path, "", Base.headers)
    attributes = JSON.parse(results.body)[0]
    ent = Entitlement.new(attributes)
    return ent
  end

  def entitlement_status()
    status = facts.attributes['system.entitlements_valid']
    return _("Unknown") if status.nil?
    return _("Valid") if status
    return _("Invalid")
  end

  #download the manifest
  def self.dl_manifest(uuid)
    include RestObject
    include HTTParty
    #do our own oautha using httparty b/c active resource truncates the binary ZIP data
    link = "https://#{AppConfig.candlepin.host}:#{AppConfig.candlepin.port}#{AppConfig.candlepin.prefix}"
    link += "?" + "oauth_key=#{AppConfig.candlepin.oauth_key}&oauth_secret=#{AppConfig.candlepin.oauth_secret}"
    t = URI.encode(link)
    res = checked_get(t)
  end
end

