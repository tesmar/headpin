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

class Product < Tableless
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :name, :attributes, :cp_id, :productContent

  def initialize(json_hash=nil)
    @json_hash = super(json_hash)
    # rails doesn't like variables called id or type<F12>

    if @json_hash != {}
      @cp_id = @json_hash["id"]
      @attributes = @json_hash["attributes"].inject({}) do |result,element|
         result[element["name"]] = element
         result
      end
      @productContent = @json_hash["productContent"]
      @name = @json_hash["name"]
    end
  end

  def self.retrieve(pid = nil)
    Product.new(JSON.parse(Candlepin::Proxy.get("/products/#{pid}")))
  end


  def support_level
    return product_attribute(:support_level)
  end

  def arch
    return product_attribute(:arch)
  end

end
