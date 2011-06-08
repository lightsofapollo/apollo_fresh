mod = Module.new do

  def mock_response(parsed, code = 200, message = 'OK')
    request = HTTParty::Request.new Net::HTTP::Post, '/'
    response = Net::HTTPOK.new('1.1', code, message)
    response = flexmock(response, {
      :body => parsed.to_xml,
    })
    HTTParty::Response.new(request, response, parsed)
  end

end

RSpec.configuration.include(mod)
