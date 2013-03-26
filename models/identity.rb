class Identity < OmniAuth::Identity::Models::ActiveRecord
  validates :email, 
    :uniqueness => { :case_sensitive => false },
    :length => { :maximum => 255 }

  before_validation do
    self.email = email.strip.downcase if attribute_present?("email")
  end

  def email=(val)
    write_attribute :email, val.strip.downcase
  end
  
end