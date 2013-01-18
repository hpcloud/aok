module ApplicationHelper
  def render_xrds(types)
    type_str = ""

    types.each { |uri|
      type_str += "<Type>#{uri}</Type>\n      "
    }

    yadis = <<EOS
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS
    xmlns:xrds="xri://$xrds"
    xmlns="xri://$xrd*($v*2.0)">
  <XRD>
    <Service priority="0">
      #{type_str}
      <URI>#{url('/openid/', true, false)}</URI>
    </Service>
  </XRD>
</xrds:XRDS>
EOS

    return 200, {'Content-Type' => 'application/xrds+xml'}, yadis
  end

  def read_json_body
    request.body.rewind  # in case someone already read it
    data = JSON.parse(request.body.read)
    if data.kind_of? Hash
      data = data.with_indifferent_access
    end
    return data
  end

end