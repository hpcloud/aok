Dir.chdir(File.dirname(__FILE__))
require File.expand_path('../config/boot', __FILE__)

use GenericErrorHandling
use DatabaseReconnect
use Rack::ContentType

maps = {
  '/'                  => RootController,
  '/uaa/Users'         => UsersController,
  '/uaa/Groups'        => GroupsController,
  '/uaa/oauth/clients' => ClientsController,
  '/uaa/oauth/users'   => UserTokensController,
  '/uaa/oauth'         => OauthController,
}
maps.each do |path, controller|
  map(path){ run controller}
end
