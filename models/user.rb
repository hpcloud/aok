class User < ActiveRecord::Base
  validates_uniqueness_of :email, :if => Proc.new {|o| !o.email.blank?}

end