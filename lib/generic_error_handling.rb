class GenericErrorHandling
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call env
    rescue => ex
      env['rack.errors'].puts ex.inspect
      env['rack.errors'].puts ex
      env['rack.errors'].puts ex.backtrace.join("\n")
      env['rack.errors'].flush

      [500, {'Content-Type' => 'application/json'}, ["Internal Server Error"].to_json]
    end
  end
end
