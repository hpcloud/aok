#!/home/aocole/.rbenv/shims/ruby
require 'base64'
require 'cgi'



def decode64(str)
  return unless str
  pad = str.length % 4
  str = str + '=' * (4 - pad) if pad > 0
  Base64.respond_to?(:urlsafe_decode64) ?
      Base64.urlsafe_decode64(str) : Base64.decode64(str.tr('-_', '+/'))
rescue ArgumentError
  raise DecodeError, "invalid base64 encoding"
end

require 'json'
def prettify(json) JSON.pretty_generate(JSON.parse(json)) end

token = ARGV[0]
if token =~ /%/
	token = CGI.unescape token
	puts "Unescaped token: #{token}"
end
parts = token.split('.')
puts "Meta:\n#{prettify(decode64(parts[0]))}\n\n"
puts "Payload:\n#{prettify(decode64(parts[1]))}\n\n"
puts "Signature:\n#{parts[2]}\n\n"
