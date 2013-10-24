class AccessToken < ActiveRecord::Base
  include Oauth2Token
  self.default_lifetime = 15.minutes
  belongs_to :refresh_token
  attr_accessor :scopes

  before_validation :make_token, :on => :create

  def to_bearer_token(with_refresh_token = false)
    bearer_token = Rack::OAuth2::AccessToken::Bearer.new(
      :access_token => self.token,
      :scope => scopes,
      :expires_in => self.expires_in # TODO: set correctly
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

  def make_token
    payload = {
      :aud => 'cloud_controller', # TODO: set correctly
      :iat => Time.now.to_i,
      :exp => self.expires_at.to_i,
      :client_id => client.identifier,
      :scope => scopes,
      :jti => SecureRandom.uuid # TODO: ensure unique, should probably
                                # be stored as a separate db column
    }
    if identity
      payload.merge!({
        :user_id => identity.guid.to_s, # TODO: make this a guid
        :sub => identity.guid.to_s, # TODO: make this a guid
        :user_name => identity.username,
        :email => identity.email,
      })
    end

    self.token = CF::UAA::TokenCoder.encode(
      payload,
      {
        :skey => AppConfig[:jwt][:token][:signing_key]
      }
    )
  end
end
