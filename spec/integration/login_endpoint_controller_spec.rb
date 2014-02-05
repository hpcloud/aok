require 'spec_helper'

def app
  RootController
end
def session
  last_request.env['rack.session']
end
describe 'LoginEndpoint Controller' do

  context "with LDAP strategy" do
    before(:all) do
      Aok::Config::Strategy.remove
      AppConfig[:strategy][:use] = :ldap
      AppConfig[:strategy][:ldap][:allowed_groups] = nil
      AppConfig[:strategy][:ldap][:admin_groups] = nil
      Aok::Config::Strategy::LDAP.setup
      OmniAuth.config.test_mode = true
    end

    before(:each) do
      AppConfig[:strategy][:ldap][:allowed_groups] = nil
      AppConfig[:strategy][:ldap][:admin_groups] = nil
      u = Identity.find_by_username('andrewc')
      u.destroy if u
    end

    it "uses LDAP strategy" do
      ApplicationController.settings.strategy.should eq(:ldap)
      ldap = ApplicationController.middleware.detect{|m| m.first == OmniAuth::Strategies::LDAP}
      developer = ApplicationController.middleware.detect{|m| m.first == OmniAuth::Strategies::Developer}
      ldap.should_not be_nil
      developer.should be_nil
    end

    it "allows all with no group restrictions set" do
      OmniAuth.config.mock_auth[:default] = {
        :provider => 'ldap',
        :info => {
          :email => 'andrewc@activestate.com',
          :nickname => 'andrewc'
        },
        :extra => {
          :raw_info => {
            AppConfig[:strategy][:ldap][:uid] => 'andrewc'
          }
        }
      }

      AppConfig[:strategy][:ldap][:allowed_groups] = nil

      post '/uaa/login.do'
      last_response.should be_redirect
      follow_redirect!
      last_request.url.should eq("http://example.org/uaa")
    end

    it "denies when groups info not present" do
      OmniAuth.config.mock_auth[:default] = {
        :provider => 'ldap',
        :info => {
          :email => 'andrewc@activestate.com',
          :nickname => 'andrewc'
        },
        :extra => {
          :raw_info => {
            AppConfig[:strategy][:ldap][:uid] => 'andrewc'
          }
        }
      }

      AppConfig[:strategy][:ldap][:allowed_groups] = %W{friends}

      post '/uaa/login.do'
      last_response.status.should eq(403)
    end

    it "denies when required groups not present" do
      OmniAuth.config.mock_auth[:default] = {
        :provider => 'ldap',
        :info => {
          :email => 'andrewc@activestate.com',
          :nickname => 'andrewc'
        },
        :extra => {
          :raw_info => {
            AppConfig[:strategy][:ldap][:uid] => 'andrewc'
          },
          :groups => %W{losers}
        }
      }

      AppConfig[:strategy][:ldap][:allowed_groups] = %W{friends}

      post '/uaa/login.do'
      last_response.status.should eq(403)
    end

    it "allows when required group present" do
      OmniAuth.config.mock_auth[:default] = {
        :provider => 'ldap',
        :info => {
          :email => 'andrewc@activestate.com',
          :nickname => 'andrewc'
        },
        :extra => {
          :raw_info => {
            AppConfig[:strategy][:ldap][:uid] => 'andrewc'
          },
          :groups => %W{friends}
        }
      }

      AppConfig[:strategy][:ldap][:allowed_groups] = %W{friends}

      post '/uaa/login.do'
      last_response.should be_redirect
      follow_redirect!
      last_request.url.should eq("http://example.org/uaa")
    end

    it "allows when one of required groups present" do
      OmniAuth.config.mock_auth[:default] = {
        :provider => 'ldap',
        :info => {
          :email => 'andrewc@activestate.com',
          :nickname => 'andrewc'
        },
        :extra => {
          :raw_info => {
            AppConfig[:strategy][:ldap][:uid] => 'andrewc'
          },
          :groups => %W{friends}
        }
      }

      AppConfig[:strategy][:ldap][:allowed_groups] = %W{friends activators}

      post '/uaa/login.do'
      last_response.should be_redirect
      follow_redirect!
      last_request.url.should eq("http://example.org/uaa")
    end


    it "grants admin when admin group present" do
      OmniAuth.config.mock_auth[:default] = {
        :provider => 'ldap',
        :info => {
          :email => 'andrewc@activestate.com',
          :nickname => 'andrewc'
        },
        :extra => {
          :raw_info => {
            AppConfig[:strategy][:ldap][:uid] => 'andrewc'
          },
          :groups => %W{friends}
        }
      }

      AppConfig[:strategy][:ldap][:admin_groups] = %W{friends activators}

      post '/uaa/login.do'
      last_response.should be_redirect
      follow_redirect!
      last_request.url.should eq("http://example.org/uaa")
      expect(session[:auth_username]).to eq('andrewc')
      user = Identity.find_by_username(session[:auth_username])
      expect(user.authorities_list).to include('cloud_controller.admin')
    end

    it "doesn't grant admin when admin group absent" do
      OmniAuth.config.mock_auth[:default] = {
        :provider => 'ldap',
        :info => {
          :email => 'andrewc@activestate.com',
          :nickname => 'andrewc'
        },
        :extra => {
          :raw_info => {
            AppConfig[:strategy][:ldap][:uid] => 'andrewc'
          },
          :groups => []
        }
      }

      AppConfig[:strategy][:ldap][:admin_groups] = %W{friends activators}

      post '/uaa/login.do'
      last_response.should be_redirect
      follow_redirect!
      last_request.url.should eq("http://example.org/uaa")
      expect(session[:auth_username]).to eq('andrewc')
      user_after = Identity.find_by_username(session[:auth_username])
      expect(user_after.authorities_list).to_not include('cloud_controller.admin')
    end



  end
end
