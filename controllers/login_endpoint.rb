module LoginEndpoint
  def self.included(base)

    # Internal Login
    # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#internal-login-post-logindo
    base.post '/uaa/login.do' do
      email = auth_hash[:info][:email]
      user = env['omniauth.identity']
      set_current_user(user)

      if env["aok.block"] # legacy login
        env["aok.block"].call(user)
        return
      end

      if env["aok.no_openid"] # legacy login
        return {:email => email}.to_json
      end

      redirect '/openid/complete', 302
    end
  end
end