include Pundit
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  before_action :require_login
  protect_from_forgery with: :exception
  helper_method :current_user, :current_user_admin?

  def gender(i)
    if i == 0
      return false
    else
      return true
    end
  end

  def get_padecimiento(id)
    Lookup.find(id).name
  end

  def get_age(dob)
    now = Time.now.utc.to_date
    now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
  end

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

  def id_to_value_direccion(id)
    return Lookup.where(id: id).first.value
  end
end
