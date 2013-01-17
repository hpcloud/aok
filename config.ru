Dir.chdir(File.dirname(__FILE__))
require './config/dependencies'

maps = {
  '/'        => ApplicationController,
  '/openid'  => OpenidController,
  '/users'   => UsersController
}
maps.each do |path, controller|
  map(path){ run controller}
end


