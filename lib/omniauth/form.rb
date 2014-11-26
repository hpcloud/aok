require 'omniauth'

module OmniAuth
  class Form
    DEFAULT_CSS = '' unless defined? DEFAULT_CSS

    attr_accessor :options

    def initialize(options = {})
      options[:title] ||= "Authentication Info Required"
      options[:header_info] ||= ""
      self.options = options

      @html = ""
      @with_custom_button = false
      header(options[:title],options[:header_info])
    end

    def self.build(options = {},&block)
      form = OmniAuth::Form.new(options)
      if block.arity > 0
        yield form
      else
        form.instance_eval(&block)
      end
      form
    end

    def label_field(text, target)
      @html << "\n<div class='form-group'><label class='col-lg-2 control-label' for='#{target}'>#{text}</label>"
      self
    end

    def input_field(type, name, label=nil)
      label ||= name
      @html << "\n<input type='#{type}' class='form-control' id='#{name}' name='#{name}' placeholder='#{label}' required />"
      self
    end

    def text_field(label, name)
      label_field(label, name)
      input_field('text', name, label)
      self
    end

    def password_field(label, name)
      label_field(label, name)
      input_field('password', name, label)
      self
    end

    def button(text)
      @with_custom_button = true
      @html << "\n" << '<button class="signin-button btn btn-lg btn-primary btn-block" type="submit" data-loading-text="Signing in...">' << text << '</button>'
    end

    def html(html)
      @html << html
    end

    def fieldset(legend, options = {}, &block)
      @html << "\n<fieldset#{" style='#{options[:style]}'" if options[:style]}#{" id='#{options[:id]}'" if options[:id]}>\n  <legend>#{legend}</legend>\n"
      self.instance_eval(&block)
      @html << "\n</fieldset>"
      self
    end

    def header(title,header_info)
      @html << <<-HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
        <link id="favicon" rel="shortcut icon" type="image/png" href="" />
        <title>#{title}</title>
        <link href="/console/css/compiled/console.min.css" rel="stylesheet" />
        <link href="/aok/aok.css" rel="stylesheet" />
        <script type="text/javascript">
          $CC_URL = "//#{cc_url}"
        </script>
        <script src="/console/js/lib/jquery/jquery-1.10.1.min.js"></script>
        <script src="/console/js/lib/bootstrap/js/bootstrap.min.js"></script>
        <script src="/console/js/lib/async/async.js"></script>
        <script src="/aok/aok.js"></script>
        #{header_info}
      </head>
      <body class="login" style="display:none;">
        <div id="header-container">
          <nav class="navbar navbar-default navbar-inverse navbar-fixed-top" role="navigation">
          </nav>
        </div>
        <div class="page_wrapper">
          <div class="container">
            <form id="login_form" class="form-signin" method='post' #{"action='#{options[:url]}' " if options[:url]}noValidate='noValidate'>
                <h2 class="form-signin-heading">#{title}</h2>
                <div id="failed-login-alert" class="alert alert-danger hide">Your attempt to sign in failed. Please try again.</div>

      HTML
      self
    end

    def footer
      return self if @footer
      @html << "\n" << '<button class="signin-button btn btn-lg btn-primary btn-block" type="submit" data-loading-text="Signing in...">Sign in</button>' unless @with_custom_button
      @html << <<-HTML
                </form>
                <div class='clearfix'></div>
          </div>
        </div>
      </body>
      </html>
      HTML
      @footer = true
      self
    end

    def to_html
      footer
      @html
    end

    def to_response
      footer
      Rack::Response.new(@html).finish
    end

    def cc_url
      CCConfig[:external_uri]
    end

  end
end
