class SessionsController < ApplicationController
  layout false
  skip_before_action :require_login, only: [:create, :destroy, :login]
  def create
    user = User.from_omniauth(env["omniauth.auth"])
    puts "my user is #{user.inspect}"
    session[:user_id] = user.id
    redirect_to tables_url
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path
  end

  def login
  end
end
