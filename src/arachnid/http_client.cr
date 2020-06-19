require "http/client"

module Arachnid
  module HTTPClient
    abstract def exec(method : String, path, headers : HTTP::Headers? = nil, body : HTTP::Client::BodyType = nil) : HTTP::Client::Response
  end
end
