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

class Event < Tableless
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :messageText, :timeStamp, :uuid

  def initialize(json_hash=nil)
    @json_hash = super(json_hash)
    # rails doesn't like variables called id or type
    if @json_hash != {}
      @uuid = @json_hash["id"]
      @messageText = @json_hash["messageText"]
      @timeStamp = DateTime.parse(@json_hash["timestamp"])
    end
  end

  def self.retrieve_by_org(key)
    self.retrieve_by("/owners/#{key}/events")
  end

  def self.retrieve_by_consumer(key)
    self.retrieve_by("/consumers/#{key}/events")
  end

  private

  def self.retrieve_by(uri)
    events = []
    json_events = JSON.parse(Candlepin::Proxy.get(uri))
    json_events.each do |json_event|
      events << Event.new(json_event)
    end
    events
  end

end
