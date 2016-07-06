include Pundit
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  before_action :require_login
  protect_from_forgery with: :exception
  helper_method :current_user, :current_user_admin?

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
    @current_user
  end

  def require_login
    redirect_to root_path, notice: 'You are not logged in!' unless current_user
  end

  def current_user_admin?
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
    @current_user.admin_level == 83
  end
end
