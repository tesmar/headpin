module SystemsHelper
  def architecture_select
    select(:arch, "arch_id",
             System.architectures {|a| [a.id, a.name]},
             {:prompt => _('Select Architecture'), :id=>"arch_field", :tabindex => 2})
  end
  def virtual_buttons
    radio_button("system_type","virtualized", "physical" ) + _("Physical") +
    radio_button("system_type","virtualized", "virtual" ) + _("Virtual")
  end
end
