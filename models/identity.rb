class Identity < OmniAuth::Identity::Models::ActiveRecord
  validates :email, 
    :uniqueness => { :case_sensitive => false },
    :length => { :maximum => 255 }
  
end