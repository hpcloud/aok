module CurrentUserHelper
  def current_user
    return nil unless session[:auth_email]
    return @user if @user && @user.email == session[:auth_email]
    @user = User.find_by_email(session[:auth_email])
    session.delete(:auth_email) unless @user
    return @user
  end

  def set_current_user(user)
    if !user.valid?
      raise ArgumentError, "Can't log in an invalid user."
    end
    session[:auth_email] = user.email
  end
end
