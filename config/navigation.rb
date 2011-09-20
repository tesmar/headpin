# Configures your navigation
SimpleNavigation::Configuration.run do |navigation|

  navigation.autogenerate_item_ids = false
  navigation.id_generator = Proc.new {|key| "kp-#{key}"}

  navigation.items do |top_level|

    top_level.item :dashboard, _("Dashboard"), dashboard_index_path

    top_level.item :subscriptions, _('Subscriptions'), subscriptions_path do |sub|
      sub.item :current, _('Current Subscriptions'), subscriptions_path
      sub.item :new_import, _('New Import'), new_import_path
      sub.item :imports, _('Recent Imports'), imports_path
    end

    top_level.item :systems, _("Systems"), systems_path do |systems_sub|

      systems_sub.item :details, _("Details"), systems_path do |details_sub|
        if (not @system.nil?)
          details_sub.item :edit, ("General"),
            edit_system_path(@system.uuid), :class => 'navigation_element'

          details_sub.item :facts, ("Facts"),
            facts_system_path(@system.uuid), :class => 'navigation_element'

          details_sub.item :subscriptions, _("Current Subscriptions"),
            subscriptions_system_path(@system.uuid), :class => 'navigation_element'

          #details_sub.item :avail_subscriptions, _("Available Subscriptions"),
          #  available_subscriptions_system_path(@system.uuid), :class => 'navigation_element'

          #details_sub.item :events, _("Events"), 
          #  events_system_path(@system.uuid), :class => 'navigation_element' 
        end
      end

      systems_sub.item :activation_keys, _("Activation Keys"), activation_keys_path do |keys_sub|
      end
    end

    # Hide this entire section if user is not an admin:
    top_level.item :administration, _("Admin"), admin_organizations_path,
      :if => Proc.new { @logged_in_user and @logged_in_user.superAdmin? } do |admin_sub|

        admin_sub.item :organizations, _("Organizations"),
          admin_organizations_path, :class => 'organizations' do | org_sub |
            if (not @organization.nil?)
              org_sub.item :edit, ("General"),
                edit_admin_organization_path(@organization.key), :class => 'navigation_element'

              org_sub.item :events, _("Events"),
                events_admin_organization_path(@organization.key), :class => 'navigation_element'
            end
          end

        admin_sub.item :users, _("Users"), admin_users_path, :class => 'users' do |user_sub|
        if @user
          user_sub.item :general, _("General"), edit_admin_user_path(@user), :class => "navigation_element"
          user_sub.item :roles_and_permissions, _("Roles & Permissions"), "/admin/users/#{@user.username}/roles", :class => "navigation_element"
        end
      end
        admin_sub.item(:roles, _("Roles"), admin_roles_path) 
    end
  end
end
