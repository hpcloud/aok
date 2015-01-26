require 'sinatra'
class ApplicationController < Sinatra::Base ; end
require_relative '../../../controllers/login_endpoint'
require_relative '../../../controllers/oauth_controller'

module Kato
  class Config
    def self.get ; end
  end
end

describe OauthController::Helpers do
  class TestHelpers
    include OauthController::Helpers
  end
  let(:helpers) { TestHelpers.new }

  context :substitute_redirect_uri do
    def make_uri(host)
      "https://#{host}/console/oauth.html"
    end

    def set_endpoint_aliases(aliases)
      expect(Kato::Config)
        .to receive(:get)
        .with('router2g')
        .and_return({'cluster_endpoint_aliases' => aliases})
    end

    CCConfig = { :external_domain => 'api.stackato.vm' }

    it 'should replace ENDPOINT with the external domain' do
      set_endpoint_aliases []
      expect(helpers.substitute_redirect_uri make_uri('ENDPOINT'), make_uri('api.stackato.vm'))
        .to eq(make_uri('api.stackato.vm'))
    end

    it 'should replace ENDPOINT ignoring the desired uri' do
      set_endpoint_aliases []
      expect(helpers.substitute_redirect_uri make_uri('ENDPOINT'), make_uri('evil.example.com'))
        .to eq(make_uri('api.stackato.vm'))
    end

    it 'should replace ENDPOINT with desired cluster endpoint alias' do
      set_endpoint_aliases ['different.vm']
      expect(helpers.substitute_redirect_uri make_uri('ENDPOINT'), make_uri('different.vm'))
        .to eq(make_uri('different.vm'))
    end

    it 'should not replace ENDPOINT with desired unknown host' do
      set_endpoint_aliases ['different.vm']
      expect(helpers.substitute_redirect_uri make_uri('ENDPOINT'), make_uri('evil.example.com'))
        .to eq(make_uri('api.stackato.vm'))
    end

    it 'should support dev_mode' do
      expect(helpers)
        .to receive(:dev_mode?)
        .and_return(true)
      expect(helpers.substitute_redirect_uri make_uri('ENDPOINT'), make_uri('127.0.0.1'))
        .to eq(make_uri('127.0.0.1'))
    end

    it 'should not support dev_mode for the wrong host' do
      expect(helpers)
        .to receive(:dev_mode?)
        .and_return(true)
      set_endpoint_aliases []
      expect(helpers.substitute_redirect_uri make_uri('ENDPOINT'), make_uri('evil.example.com'))
        .to eq(make_uri('api.stackato.vm'))
    end
  end
end
