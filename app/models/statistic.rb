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

class Statistic < Tableless
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming


  PERPOOL = "PERPOOL"
  TOTALCONSUMER = "TOTALCONSUMERS"
  TOTALSUBSCRIPTIONCOUNT = "TOTALSUBSCRIPTIONCOUNT"
  TOTALSUBSCRIPTIONCONSUMED = "TOTALSUBSCRIPTIONCONSUMED"

  attr_accessor :valueType, :json_hash, :value

  def initialize(json_hash=nil)
    @json_hash = (json_hash ||= {})
    # rails doesn't like variables called id or type
    if @json_hash != {}
      @valueType = @json_hash["valueType"]
      @value = @json_hash["value"]
    end
  end

  def self.retrieve_all_by_org(owner_id, optional_params = {})
    oj = nil
    stats = []
    url = "/owners/#{owner_id}/statistics"
    url += "/#{optional_params[:type]}" if optional_params[:type]
    begin
      oj = JSON.parse(Candlepin::Proxy.get(url))
      oj.each do |stat_json|
        stats << Statistic.new(stat_json)
      end
      return stats
    rescue Exception => e
      Rails.logger.error "Unrecognized Stat: " + oj.to_s
      raise "Unrecognized Stat: " + oj.to_s + "\n" + e.to_s
    end
  end

end
