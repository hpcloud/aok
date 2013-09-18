Dir.chdir(File.dirname(__FILE__))
require File.expand_path('../config/boot', __FILE__)

use DatabaseReconnect
use Rack::ContentType

maps = {
  '/'                  => ApplicationController,
  '/openid'            => OpenidController,
  '/uaa/Users'         => UsersController,
  '/uaa/Groups'        => GroupsController,
  '/uaa/oauth/clients' => ClientsController,
  '/uaa/oauth/users'   => UserTokensController,
  '/logins'            => LoginsController,
  '/uaa'               => UaaController
}
maps.each do |path, controller|
  map(path){ run controller}
end
