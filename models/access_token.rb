class AccessToken < ActiveRecord::Base
  include Oauth2Token
  self.default_lifetime = 15.minutes
  belongs_to :refresh_token
  attr_accessor :scopes

  def to_bearer_token(with_refresh_token = false)
    # Sample token from UAA:
    # {
    #   "jti":"d0db6628-1b7e-48ae-aaa3-2b6b0223b209",
    #   "sub":"4416b853-b771-442b-93c0-cbb16bba66e6",
    #   "scope":[
    #     "scim.read",
    #     "scim.userids",
    #     "cloud_controller.admin",
    #     "password.write",
    #     "scim.write",
    #     "cloud_controller.write",
    #     "openid",
    #     "cloud_controller.read"
    #   ],
    #   "client_id":"vmc",
    #   "cid":"vmc",
    #   "user_id":"4416b853-b771-442b-93c0-cbb16bba66e6",
    #   "user_name":"admin",
    #   "email":"admin",
    #   "iat":1377541877,
    #   "exp":1377585077,
    #   "iss":"http://localhost:8080/uaa/oauth/token",
    #   "aud":["scim",
    #     "openid",
    #     "cloud_controller",
    #     "password"
    #   ]
    # }

    self.token = CF::UAA::TokenCoder.encode(
      {
        :aud => 'cloud_controller',
        :user_id => identity.id, # TODO: make this a guid
        :sub => identity.id, # TODO: make this a guid
        :email => identity.email,
        :iat => Time.now.to_i,
        :exp => self.expires_at.to_i,
        :user_name => identity.username,
        :client_id => client.identifier,
        :scope => scopes
      }, 
      {
        :skey => 'tokensecret'
      }
    )

    bearer_token = Rack::OAuth2::AccessToken::Bearer.new(
      :access_token => self.token,
      :expires_in => self.expires_in
    )
    if with_refresh_token
      bearer_token.refresh_token = self.create_refresh_token(
        :identity => identity,
        :client => self.client
      ).token
    end
    bearer_token
  end

  private

  def setup
    super
    if refresh_token
      self.identity = refresh_token.identity
      self.client = refresh_token.client
      self.expires_at = [self.expires_at, refresh_token.expires_at].min
    end
  end
end
