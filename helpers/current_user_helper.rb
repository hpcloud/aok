module CurrentUserHelper
  def current_user
    return nil unless session[:auth_username]
    @user = Identity.find_by_username(session[:auth_username])
    return @user
  end

  def set_current_user(user)
    unless user && user.username
      raise ArgumentError, "Can't log in a user with no username"
    end
    session[:auth_username] = user.username
  end

  def clear_current_user
    session[:auth_username] = nil
  end

  def require_user
    halt(redirect("/auth/#{settings.strategy}")) unless current_user
  end
end
