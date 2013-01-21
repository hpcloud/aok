module CurrentUserHelper
  def current_user
    return nil unless session[:auth_email]
    @user = Identity.new(:email => session[:auth_email])
    return @user
  end

  def set_current_user(user)
    unless user && user.email
      raise ArgumentError, "Can't log in a user with no email"
    end
    session[:auth_email] = user.email
  end

  def clear_current_user
    session[:auth_email] = nil
  end
end
