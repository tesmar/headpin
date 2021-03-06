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

module BreadcrumbHelper

  def add_crumb_node!(hash, id, url, name, trail, params={}, attributes ={})
    cache = false || params[:cache] #default to false
    hash[id] = {:name=>name, :url=>url, :trail=>trail, :cache=>cache}
    hash[id][:content] = params[:content] if params[:content]
    hash[id][:scrollable] = true if params[:scrollable]
    hash[id][:client_render] = true if params[:client_render]
    hash[id] = hash[id].merge(attributes)
  end

  module ChangesetBreadcrumbs
    def generate_cs_breadcrumb
      bc = {}
      add_crumb_node!(bc, "changesets", "", _("Changesets"), [], {:client_render => true})

      @changesets.each{|cs|
        add_crumb_node!(bc, changeset_bc_id(cs), "", cs.name, ['changesets'],
                        {:client_render => true}, {:is_new=>cs.state == Changeset::NEW})

        cs.involved_products.each{|product|
          #product details
          add_crumb_node!(bc, product_cs_bc_id(cs, product), "", product.name, ['changesets', changeset_bc_id(cs)],
                          {:client_render => true})
          #packages
          add_crumb_node!(bc, packages_cs_bc_id(cs, product), "",  _("Packages"),
                          ['changesets', changeset_bc_id(cs),product_cs_bc_id(cs, product)], {:client_render => true})

          #errata
          add_crumb_node!(bc, errata_cs_bc_id(cs, product), "",  _("Errata"),
                          ['changesets', changeset_bc_id(cs), product_cs_bc_id(cs, product)], {:client_render => true})

          #repos
          add_crumb_node!(bc, repos_cs_bc_id(cs, product), "",  _("Repositories"),
                          ['changesets', changeset_bc_id(cs), product_cs_bc_id(cs, product)], {:client_render => true})

          #repos
          add_crumb_node!(bc, deps_cs_bc_id(cs, product), "",  _("Dependencies"),
                          ['changesets', changeset_bc_id(cs), product_cs_bc_id(cs, product)], {:client_render => true})


        }
      } if @changesets
      bc.to_json
    end

    def changeset_bc_id cs
      "changeset_#{cs.id}" if cs
    end

    def product_cs_bc_id cs, product
      "product-cs_#{cs.id}_#{product.id}" if cs
    end

    def packages_cs_bc_id cs, product
      "package-cs_#{cs.id}_#{product.id}" if cs
    end

    def errata_cs_bc_id cs, product
      "errata-cs_#{cs.id}_#{product.id}" if cs
    end

    def repos_cs_bc_id cs, product
      "repo-cs_#{cs.id}_#{product.id}" if cs
    end

    def deps_cs_bc_id cs, product
      "deps-cs_#{cs.id}_#{product.id}" if cs
    end
  end

  module ContentBreadcrumbs
    def details_path product_id=nil
      promotion_details_path(@organization.cp_key, @environment.name, :product_id=>product_id)
    end

    #  Generates a json structure of the breadcrumb, consisting of a hash map of:
    #   :id =>  {:url, :name, :trail}   where name is a human readable name, and :trail is
    #                                    a list of other :ids creating the trail leading up to it
    #
    def generate_content_breadcrumb
      bc = {}
      content_crumb_id = "content"
      products_crumb_id = "products"

      add_crumb_node!(bc, content_crumb_id, details_promotion_path(@environment.name) ,
                      _("Content"), [], {:cache =>true, :content=>render(:partial=>"detail")})
      add_crumb_node!(bc, "all_errata", errata_promotion_path(@environment.name),
                      _("All Errata"), [content_crumb_id], {:scrollable=>true})
      add_crumb_node!(bc, products_crumb_id, products_promotion_path(@environment.name),
                      _("Products"), [content_crumb_id], {:cache=>true, :content=>render(:partial=>"products", :locals=>{:products=>@products, :changeset=>@changeset})})

      for prod in @products
        product_id = product_bc_id(prod)
        #top of this product
        add_crumb_node!(bc, product_id, details_promotion_path(@environment.name, :product_id=>prod.id),
                        prod.name, [content_crumb_id,products_crumb_id], {:cache=>true, :content=>render(:partial=>"detail", :locals=>{:product=>prod})})

        #product,packages
        add_crumb_node!(bc, packages_bc_id(prod), packages_promotion_path(@environment.name, :product_id=>prod.id, :changeset_id=>changeset_id(@changeset)),
                        _("Packages"), [content_crumb_id,products_crumb_id, product_id], {:scrollable=>true})

        #product_errata
        add_crumb_node!(bc, errata_bc_id(prod), errata_promotion_path(@environment.name, :product_id=>prod.id, :changeset_id=>changeset_id(@changeset)),
                        _("Errata"), [content_crumb_id,products_crumb_id, product_id], {:scrollable=>true})

        #product_repos
        add_crumb_node!(bc, repo_bc_id(prod), repos_promotion_path(@environment.name, :product_id=>prod.id, :changeset_id=>changeset_id(@changeset)),
                        _("Repos"), [content_crumb_id,products_crumb_id, product_id], {:scrollable=>true})

        #product_distributions
        add_crumb_node!(bc, distribution_bc_id(prod), distributions_promotion_path(@environment.name, :product_id=>prod.id, :changeset_id=>changeset_id(@changeset)),
                        _("Distributions"), [content_crumb_id,products_crumb_id, product_id], {:scrollable=>true})

      end
      bc.to_json
    end

    def product_bc_id product
      "details_#{product.id}"
    end

    def packages_bc_id product
      "packages_#{product.id}"
    end

    def errata_bc_id product
      "errata_#{product.id}"
    end

    def repo_bc_id product
      "repo_#{product.id}"
    end

    def changeset_id cs
      return cs.id if cs
    end

    def distribution_bc_id product
      "distribution_#{product.id}"
    end

  end

  module RolesBreadcrumbs
    def generate_roles_breadcrumb
      bc = {}
      add_crumb_node!(bc, "roles", "", _(@role.name), [],
                      {:client_render => true})
      add_crumb_node!(bc, "role_permissions", "", _("Permissions"), ['roles'],
                      {:client_render => true})
      add_crumb_node!(bc, "role_users", "", _("Users"), ['roles'],
                      {:client_render => true})
      add_crumb_node!(bc, "global", "", _("Global Permissions"), ['roles', "role_permissions"],
                      {:client_render => true}, { :count => 0, :permission_details => get_global_verbs_and_tags })

      @organizations.each{|org|
        add_crumb_node!(bc, organization_bc_name(org, org.key), "", org.displayName, ['roles', 'role_permissions'],
                        {:client_render => true}, { :count => 0})
      } if @organizations
      User.retrieve_all.each{ |user|
        add_crumb_node!(bc, user_bc_id(user), "", user.username, ['roles', 'role_users'],
                        {:client_render => true}, { :has_role => false })
      }

      @role.users.each{ |user|

        bc[user_bc_id2(user)][:has_role] = true if bc[user_bc_id2(user)] && !bc[user_bc_id2(user)][:has_role].nil?
      }

      if @role.permissions
        @role.permissions.each{ |perm|
          add_permission_bc(bc, perm, true)
        }
      end

      bc.to_json
    end

    def add_permission_bc(bc, perm, adjust_count)
        add_crumb_node!(bc, permission_bc_id(perm), "", permission_short_name(perm), ['roles', 'role_permissions', organization_bc_name(perm["owner"], perm["owner"]["key"])],
                    { :client_render => true },
                    { :organization => "organization_" + perm["owner"]["key"],
                      :type_name =>  perm["access"], :type => 'type',
                      :cust_id => perm["id"]
                    })
        if adjust_count
          bc[organization_bc_name(perm["owner"], perm["owner"]["key"])][:count] += 1
        end
    end

    def get_global_verbs_and_tags
      {}
    end

    def organization_bc_id organization
      if organization
        "organization_#{organization.id}"
      else
        "global"
      end
    end

    def organization_bc_name(organization, key)
      if organization
        "organization_#{key}"
      else
        "global"
      end
    end

    def user_bc_id(user)
      "user_#{user.username}"
    end

    def user_bc_id2(user)
      "user_" + user["username"]
    end

    def permission_short_name(permission)
      permission["access"] + "_" +  permission["id"][-4..-1]
    end

    def permission_bc_id(permission)
      if permission
        "permission_" + permission["owner"]["key"] + "_" + permission["id"] + "_" + permission["access"]
      end
    end

    def permission_global_bc_id permission
      "permission_global_" + permission["id"]
    end
  end
end
