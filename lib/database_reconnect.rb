# This is a rack middleware to catch exceptions indicitive of
# db connection issues and automatically attempt a reconnect
# to the db.
require 'active_record/errors'
class DatabaseReconnect
  def initialize(app)
    @app = app
  end

  def call(env)
    tries ||= 1
    @app.call env
  rescue ActiveRecord::StatementInvalid, NoMethodError => e
    # These are both to address the possibility of getting disconnected from
    # the database. The second one is a result of a bug in rails:
    # https://github.com/rails/rails/issues/10917
    if e.message =~ /^PG::Error: connection (is closed|not open)/i ||
       (e.kind_of?(NoMethodError) && e.message =~ /error_field/)
      if tries > 0
        tries -= 1
        lognow env, "Experienced a database interruption. Verifying DB connection and retrying."
        ActiveRecord::Base.connection.verify!
        retry
      else
        lognow env, "Verifying DB connection didn't help. Bailing with 500 error."
        lognow env, e
        lognow env, e.backtrace.join("\n")
        return [500, {'Content-Type' => 'text/html'}, "<h1>Internal Server Error</h1>"]
      end
    else
      lognow env, "Checked if this was a DB connection error and it doesn't
      seem to be. re-raising."
      raise e
    end
  end

  def lognow env, txt
    env['rack.errors'].puts txt
    env['rack.errors'].flush
  end

end
