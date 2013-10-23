if AppConfig[:oauth] && AppConfig[:oauth][:clients]
  AppConfig[:oauth][:clients].each do |name, config|
    identifier = config[:id] || name
    c = Client.find_by_identifier(identifier) || Client.new
    c.name = name
    c.authorities = config[:authorities]
    c.secret = config[:secret] if config[:secret]
    c.authorized_grant_types = config[:authorized_grant_types]
    c.scope = config[:scope]
    c.website = config[:redirect_uri]
    c.redirect_uri = config[:redirect_uri]
    c.identity = Identity.first
    c.identifier = identifier
    c.save!
  end
end
