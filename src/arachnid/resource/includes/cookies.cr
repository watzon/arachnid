module Arachnid
  class Resource
    module Cookies
      # Reserved names used within Cookie strings
      RESERVED_COOKIE_NAMES = Regex.new("^(?:Path|Expires|Domain|Secure|HTTPOnly)$", :ignore_case)

      # The raw Cookie String sent along with the resource.
      def cookie
        @response.headers["Set-Cookie"]? || ""
      end

      # The Cookie values sent along with the resource.
      def cookies
        @response.cookies
      end
    end
  end
end
