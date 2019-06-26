module Arachnid
  class CookieJar
    include Enumerable(HTTP::Cookies)

    @params : Hash(String, HTTP::Cookies)

    @cookies : HTTP::Cookies

    @dirty : Set(String)

    # Creates a new `CookieJar`
    def initialize
      @params = {} of String => HTTP::Cookies
      @cookies = HTTP::Cookies.new
      @dirty = Set(String).new
    end

    # Iterates over the host-name and cookie value pairs in the jar.
    def each(&block)
      @params.each do |kp|
        yield kp
      end
    end

    # Returns all relevant cookies in a single string for the named
    # host or domain.
    def [](host : String)
      @params[host]? || HTTP::Cookies.new
    end

    # Add a cookie to the jar for a particular domain.
    def []=(host : String, cookies : HTTP::Cookies)
      @params[host] ||= HTTP::Cookies.new

      cookies.each do |cookie|
        if @params[host][cookie.name]? != cookie.value
          cookies.each do |c|
            @params[host] << c
          end
          @dirty.add(host)

          break
        end
      end

      cookies
    end

    # Retrieve cookies for a domain from the response.
    def from_page(page)
      cookies = page.cookies

      unless cookies.empty?
        self[page.url.host.to_s] = cookies
        return true
      end

      false
    end

    # Returns the pre-encoded Cookie for a given host.
    def for_host(host)
      if @dirty.includes?(host)
        values = [] of String

        cookies_for_host(host).each do |cookie|
          values << cookie.to_cookie_header
        end

        @cookies[host] = values.join("; ")
        @dirty.delete(host)
      end

      @cookies[host]?
    end

    # Returns raw cookie value pairs for a given host. Includes cookies
    # set on parent domains.
    def cookies_for_host(host)
      host_cookies = @params[host]? || HTTP::Cookies.new
      subdomains = host.split('.')

      while subdomains.size > 2
        subdomains.shift

        if parent_cookies = @params[subdomains.join('.')]?
          parent_cookies.each do |cookie|
            # copy in the parent cookies, only if they haven't been
            # overridden yet.
            unless host_cookies.has_key?(cookie.name)
                host_cookies[cookie.name] = cookie.value
            end
          end
        end
      end

      host_cookies
    end

    # Clear out the jar, removing all stored cookies.
    def clear!
      @params.clear
      @cookies.clear
      @dirty.clear
      self
    end

    # Size of the cookie jar.
    def size
      @params.size
    end

    # Inspects the cookie jar.
    def inspect
      "#<#{self.class}: #{@params.inspect}>"
    end
  end
end
