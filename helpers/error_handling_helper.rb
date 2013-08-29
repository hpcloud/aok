module ErrorHandlingHelper
  error Aok::Errors::AokError do
    e = env['sinatra.error']
    return e.http_status, e.http_headers, e.body
  end

  error Rack::OAuth2::Server::Authorize::BadRequest do
    e = env['sinatra.error']
    # need this to emulate the redirect response that UAA produces
    e.protocol_params_location = :fragment
    e.finish
  end
end
