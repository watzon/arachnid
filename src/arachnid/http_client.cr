require "./http_client/**"

module Arachnid
  abstract class HTTPClient

    property endpoint : URI?

    property read_timeout : Int32

    property connect_timeout : Int32

    property max_redirects : Int32

    property headers : Hash(String, String)

    def initialize(
      endpoint : URI? = nil,
      read_timeout : Int32? = nil,
      connect_timeout : Int32? = nil,
      max_redirects : Int32? = nil,
      headers : Hash(String, String)? = nil
    )
      @endpoint = endpoint
      @read_timeout = read_timeout || Arachnid.read_timeout
      @connect_timeout = connect_timeout || Arachnid.connect_timeout
      @max_redirects = max_redirects || Arachnid.max_redirects
      @headers = headers || {} of String => String
    end

    {% for method in [:get, :post, :put, :patch, :delete] %}
      def {{ method.id }}(path, options)
        request({{ method.id.stringify }}, path, options)
      end

      def {{ method.id }}(path, **options)
        request({{ method.id.stringify }}, path, **options)
      end
    {% end %}

    abstract def request(method, path, options)

    def request(method, path, **options)
      request(method, path, options)
    end
  end
end
