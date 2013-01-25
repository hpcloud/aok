%W{
  pathname

  openid
  openid/consumer/discovery
  openid/extensions/sreg
  openid/extensions/pape
  openid/store/filesystem
}.each{|l| require l}

class OpenidController < ApplicationController
  include OpenID::Server

  get_and_post '/?' do
    begin
      oidreq = server.decode_request(params)
    rescue ProtocolError => e
      # invalid openid request, so just display a page with an error message
      logger.debug "Invalid openid request: #{e.to_s}"
      halt 400, "Invalid openid request"
    end

    # no openid.mode was given
    unless oidreq
      logger.debug "No oidreq"
      halt "This is an OpenID server endpoint!"
    end
    oidresp = nil

    if oidreq.kind_of?(CheckIDRequest)

      identity = oidreq.identity

      if oidreq.id_select
        if oidreq.immediate
          oidresp = oidreq.answer(false)
        elsif current_user.nil?
          # The user hasn't logged in.
          redirect_to_auth(oidreq)
          return
        else
          # Else, set the identity to the one the user is using.
          identity = url_for_user
        end
      end

      if oidresp
        nil
      elsif self.is_authorized(identity, oidreq.trust_root)
        oidresp = oidreq.answer(true, nil, identity)

        # add the sreg response if requested
        add_sreg(oidreq, oidresp)
        # ditto pape
        add_pape(oidreq, oidresp)

      elsif oidreq.immediate
        server_url = url('/')
        oidresp = oidreq.answer(false, server_url)

      else
        return redirect_to_auth(oidreq)
      end

    else
      oidresp = server.handle_request(oidreq)
    end

    self.render_response(oidresp)
  end

  def server
    if @server.nil?
      server_url = url('/')
      dir = Pathname.new('.').join('openid-store')
      store = OpenID::Store::Filesystem.new(dir)
      @server = Server.new(store, server_url)
    end
    return @server
  end

  def redirect_to_auth(oidreq)
    session[:last_oidreq] = oidreq
    redirect '/auth'
  end

  get '/idp_xrds' do
    types = [
             OpenID::OPENID_IDP_2_0_TYPE,
            ]

    render_xrds(types)
  end

  get '/complete' do
    oidreq = session[:last_oidreq]
    unless oidreq
      logger.info "No openid request was found in the session. 
      This can sometimes be caused by clock skew between the server
      and the user-agent causing the cookie to expire prematurely."
      halt "This is an OpenID server endpoint!"
    end

    session[:last_oidreq] = nil
    oidresp = nil

    if current_user
      identity = url_for_user
      session[:approvals] ||= []
      session[:approvals] << oidreq.trust_root

      oidresp = oidreq.answer(true, nil, identity)
      add_sreg(oidreq, oidresp)
    else
      oidresp = oidreq.answer(false)
    end
    return self.render_response(oidresp)
  end

  protected


  def approved(trust_root)
    return false if session[:approvals].nil?
    return session[:approvals].member?(trust_root)
  end

  def is_authorized(identity_url, trust_root)
    return (session[:username] and (identity_url == url_for_user) and self.approved(trust_root))
  end

  def add_sreg(oidreq, oidresp)
    # check for Simple Registration arguments and respond
    sregreq = OpenID::SReg::Request.from_openid_request(oidreq)

    return if sregreq.nil?
    sreg_data = {
      'email' => current_user.email
    }

    sregresp = OpenID::SReg::Response.extract_response(sregreq, sreg_data)
    oidresp.add_extension(sregresp)
  end

  # XXX: Make this return accurate information.
  def add_pape(oidreq, oidresp)
    papereq = OpenID::PAPE::Request.from_openid_request(oidreq)
    return if papereq.nil?
    paperesp = OpenID::PAPE::Response.new
    paperesp.nist_auth_level = 0 # we don't even do auth at all!
    oidresp.add_extension(paperesp)
  end

  def render_response(oidresp)
    if oidresp.needs_signing
      signed_response = server.signatory.sign(oidresp)
    end
    web_response = server.encode_response(oidresp)

    case web_response.code
    when HTTP_OK then web_response.body
    when HTTP_REDIRECT then redirect(web_response.headers['location'])
    else [400, web_response.body]
    end
  end

  def url_for_user
    url("/users/#{current_user.email}", true, false)
  end
end