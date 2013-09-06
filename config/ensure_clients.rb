if AppConfig[:oauth] && AppConfig[:oauth][:clients]
  AppConfig[:oauth][:clients].each do |name, config|
    next if Client.find_by_identifier(config[:id])
    c = Client.new
    c.name = name
    c.authorities = config[:authorities]
    c.secret = config[:secret]
    c.authorized_grant_types = config[:authorized_grant_types]
    c.scope = config[:scope]
    c.website = config[:redirect_uri]
    c.redirect_uri = config[:redirect_uri]
    c.identity = Identity.first
    c.save!
    c.identifier = config[:id]
    c.save!
  end
end