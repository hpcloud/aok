module ErrorHandlingHelper
  def self.included(base)

    base.error Sinatra::NotFound do
      content_type 'text/plain'
      [404, 'Not Found']
    end

    base.error Aok::Errors::AokError do
      e = env['sinatra.error']
      return e.http_status, e.http_headers, e.body
    end

    base.error Rack::OAuth2::Server::Authorize::BadRequest do
      e = env['sinatra.error']
      e.protocol_params_location = :fragment
      unless e.redirect_uri
        logger.error "No Redirect Uri!"
        response = Rack::Response.new
        response.status = 400
        response.header['Content-Type'] = 'application/json'
        response.write({
          :error => 'bad_request',
          :error_description => "Incorrect redirect_uri"
        }.to_json)
        env['aok.finishable_error'] = response
        return response.finish
      end
      # e.finish will either return directly to the client
      # or the stashed error will be handled by UaaController#respond, depending on context
      env['aok.finishable_error'] = e
      e.finish
    end

    base.error JsonMessage::ValidationError do
      e = env['sinatra.error']
      error_string = e.to_s.gsub('Unknown field', 'Unrecognized field')
      return 400, {
          :error => 'bad_request',
          :error_description => error_string,
          :message => error_string
        }.to_json
    end
  end
end
