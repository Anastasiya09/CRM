module ApplicationHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::UrlHelper

  MENU = YAML.load_file("#{Rails.root}/config/menu.yml")

  def site_title(location)
    if location
      "#{location} - CRM"
    else
      'CRM'
    end
  end

  def sub_menu_action(name, path, controller,
                      action, param_name = :some, param_value = nil)
    if active_action?(controller, action, param_name, param_value)
      class_name = 'active'
    end
    content_tag(:li, '', class: class_name) do
      link_to(name, path)
    end
  end

  def active_action?(controller, action, param_name, param_value)
    return false if params[param_name] != param_value
    params[:controller] == controller && params[:action] == action
  end

  # OPTIMIZE
  def sub_menu_type
    return 'sale_sub_menu' if params[:type] == 'SALE'
    return 'hh_sub_menu' if params[:type] == 'CANDIDATE'
  end

  def current_user?(user)
    user == current_user
  end

  # NEED REWRITE
  def generate_link(link)
    content_tag(:div, class: "link l_#{link.id}") do
      buffer = ActiveSupport::SafeBuffer.new
      buffer << link_to(link.alt, link.href, target: '_blank')
      buffer << link_to(image_tag(ActionController::Base.helpers.asset_path("remove-red.png")),
                      link_path(link), class: 'pull-right remove-link',
                      method: :delete, remote: true)
      buffer
    end
  end

  # NEED REWRITE
  def generate_tr_for_user(user)
    content_tag(:tr) do
      buffer = ActiveSupport::SafeBuffer.new
      buffer << content_tag(:td, user.first_name)
      buffer << content_tag(:td, user.last_name)
      buffer << content_tag(:td, user.email)
      buffer << content_tag(:td, user_status(user))
      buffer << content_tag(:td, user.current_sign_in_at)
      buffer << content_tag(:td) do
        link_to(image_tag(ActionController::Base.helpers.asset_path("remove.png")), user_path(user), data: {
          confirm: "Are you sure to remove user #{user.first_name} #{user.last_name}?"
        },
        method: :delete )
      end
      buffer
    end
  end
  
  # return all main permissions for user
  def header_menu
    return [] unless current_user
    permissions = current_user.permissions.pluck(:name)
    permissions << 'administration_section' if current_user.admin_permission?
    MENU['permissions'].select do |key, value|
      value if permissions.include? key
    end
  end

  # method can be modified in future
  def logo_link
    root_path
  end
end
