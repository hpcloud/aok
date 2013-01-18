class Identity < OmniAuth::Identity::Models::ActiveRecord
  validates_uniqueness_of :email
  
end