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

  attr_accessor :name, :attributes, :cp_id

  def initialize(json_hash=nil)
    @json_hash = super(json_hash)
    # rails doesn't like variables called id or type<F12>

    if @json_hash != {}
      @cp_id = @json_hash["id"]
      @attributes = @json_hash["attributes"].inject({}) do |result,element|
         result[element["name"]] = element
         result
      end
      @name = @json_hash["name"]
    end

    #Rails.logger.ap "NEW Prod FROM CANDLEPIN JSON:::::::::::::"
    #Rails.logger.ap self
  end 

  def self.retrieve(pid = nil)
    oj = nil
    begin
      oj = JSON.parse(Candlepin::Proxy.get("/products/#{pid}"))
      return Product.new(oj)
    rescue Exception => e
      Rails.logger.error "Unrecognized Prod: " + oj.to_s 
      raise "Unrecognized Prod: " + oj.to_s + "\n" + e.to_s 
    end
  end


  def support_level
    return product_attribute(:support_level)
  end

  def arch
    return product_attribute(:arch)
  end  

  def product_attribute(key)
    if @product_attributes.nil?
      h = {}
      if @attributes['attributes']
        @attributes['attributes'].each do |attr|
          h[attr.name.to_sym]=attr.value
        end
      end
      @product_attributes = h      
    end
    return @product_attributes[key]
  end 
end
