class User < ActiveRecord::Base
  validates_uniqueness_of :email, :if => Proc.new {|o| !o.email.blank?}

  def password=(val)
    raise ActiveRecord::RecordInvalid.new(self) unless val
    self.crypted_password = BCrypt::Password.create(val).to_s
  end

  def self.valid_login?(email, password)
    if user = find_by_email(email)
      BCrypt::Password.new(user.crypted_password) == password
    end
  end
end