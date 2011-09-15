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

class ImportRecord < Tableless
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :created, :updated, :statusMessage, :status

  def initialize(json_hash=nil)
    @json_hash = (json_hash ||= {})
    # rails doesn't like variables called id or type
    if @json_hash != {}
      @created = @json_hash["created"]
      @updated = @json_hash["updated"]
      @status = @json_hash["status"]
      @statusMessage = @json_hash["statusMessage"]
    end
    Rails.logger.ap "NEW IMPORT RECORD FROM CANDLEPIN JSON:::::::::::::"
    Rails.logger.ap self
  end

  def timestamp
    DateTime.parse @updated
  end

  def self.retrieve_by_org(key)
    import_records = []
    begin
      json_import_records = JSON.parse(Candlepin::Proxy.get("/owners/#{key}/imports"))
      json_import_records.each do |json_import_record|
        import_records << ImportRecord.new(json_import_record)
      end
    rescue Exception => e
      Rails.logger.error "Unrecognized Import Record: " + json_import_records.to_s
      raise "Unrecognized Activation Key: " + json_import_records.to_s + "\n" + e.to_s
    end
    import_records
  end

end
