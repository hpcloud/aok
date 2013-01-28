Dir.chdir(File.dirname(__FILE__))
require File.expand_path('../config/boot', __FILE__)

maps = {
  '/'        => ApplicationController,
  '/openid'  => OpenidController,
  '/users'   => UsersController,
  '/logins'  => LoginsController
}
maps.each do |path, controller|
  map(path){ run controller}
end


