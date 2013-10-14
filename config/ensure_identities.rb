if AppConfig[:scim] && AppConfig[:scim][:users]
  AppConfig[:scim][:users].each do |config_string|
    config_array = config_string.split('|')
    unless (5..6) === config_array.size
      raise "Malformed user config: #{config_string}. Correct format is username|password|email|first_name|last_name(|comma-separated-authorities)"
    end
    username, password, email, first_name, last_name, authorities = *config_array
    next if Identity.find_by_username username
    i = Identity.create!(
      :username => username,
      :password => password,
      :email => email,
      :first_name => first_name,
      :last_name => last_name
      # TODO: set authorities (groups)
    )
  end
end
