class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:username])
  end

  def after_sign_in_path_for(resource)
    if resource.group.name == "MJ"
      mj_dashboard_path # Redirection vers la page MJ
    else
      root_path # Redirection pour les autres utilisateurs
    end
  end
end
