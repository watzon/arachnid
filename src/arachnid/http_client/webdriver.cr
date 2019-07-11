module Arachnid
  abstract class HTTPClient
    class Webdriver < HTTPClient

      def request(method, path, options)
        raise "Not implemented yet"
      end

    end
  end
end
