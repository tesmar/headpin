module ActivationKeysHelper
  def subscriptions_checkboxes
    temp = @subscriptions.map do |sub|
      differentiator = sub.productAttributes["arch"] ? sub.productAttributes["arch"]["value"] : ""
      (check_box_tag 'checkgroup[]', sub.uuid) + sub.productName + " " + differentiator
    end.join("<br />").html_safe
    temp
  end
end
