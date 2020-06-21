require "./resource/*"
require "./resource/includes/*"

module Arachnid
  class Resource
    include Cookies
    include StatusCodes
    include ContentTypes

    getter uri : URI

    getter response : HTTP::Client::Response

    def initialize(uri, response)
      @uri = uri.is_a?(URI) ? uri : URI.parse(uri)
      @response = response
    end

    # Create a resource based on the Content-Type header
    # of the resource.
    def self.from_content_type(uri, response)
      headers = response.headers
      case headers.fetch("Content-Type", nil)
      when /html/
        return Resource::HTML.new(uri, response)
      when /xml/
        return Resource::XML.new(uri, response)
      when /image/
        return Resource::Image.new(uri, response)
      when /stylesheet|css/
        return Resource::Stylesheet.new(uri, response)
      when /javascript/
        return Resource::Script.new(uri, response)
      else
        Log.debug { "No resource for content type '#{headers["Content-Type"]?}'" }
        return Resource.new(uri, response)
      end
    end

    # Save this resource to a file
    def save(path)
      File.write(path, @response.body)
    end
  end
end
