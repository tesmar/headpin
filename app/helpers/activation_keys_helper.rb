module ActivationKeysHelper
  def subscriptions_checkboxes
    temp = @subscriptions.map do |sub|
      (check_box_tag 'checkgroup[]', sub.uuid) + sub.name
    end.join("<br />").html_safe
    temp
  end
end
