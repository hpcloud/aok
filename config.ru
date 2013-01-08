require './config/dependencies'

maps = {
  '/'        => ApplicationController,
  '/openid'  => OpenidController,
  '/users'   => UsersController
}
maps.each do |path, controller|
  map(path){ run controller}
end


