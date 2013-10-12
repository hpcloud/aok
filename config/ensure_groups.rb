required_groups = %W{
  openid
  password.write
  cloud_controller.read
  cloud_controller.write
  tokens.read
  tokens.write
  scim.read
  scim.write
  uaa.user
} + AppConfig[:oauth][:users][:default_authorities]

required_groups.uniq.each do |name|
  g = Group.find_or_create_by_name name
end
