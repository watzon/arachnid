require "base64"
require "./extensions/uri"
require "./auth_credential"
require "./resource"

module Arachnid
  class AuthStore
    @credentials = {} of Tuple(String?, String?, Int32?) => Hash(Array(String), AuthCredential)

    # Given a URL, return the most specific matching auth credential.
    def [](url)
      # normalize the url
      url = URI.parse(url) unless url.is_a?(URI)

      key = key_for(url)
      paths = @credentials[key]?

      return nil unless paths

      # longest path first
      ordered_paths = paths.keys.sort { |path_key|  -path_key.size }

      # directories of the path
      path_dirs = URI.expand_path(url.path).split('/').reject(&.empty?)

      ordered_paths.each do |path|
        return paths[path] if path_dirs[0, path.size] == path
      end

      nil
    end

    # Add an auth credential to the store for the supplied base URL.
    def []=(url, auth)
      # normalize the url
      url = URI.parse(url) unless url.is_a?(URI)

      # normalize the url path and split it
      paths = URI.expand_path(url.path).split('/').reject(&.empty?)

      key = key_for(url)

      @credentials[key] ||= {} of Array(String) => AuthCredential
      @credentials[key][paths] = auth
      auth
    end

    # Convenience method to add username and password credentials
    # for a named URL.
    def add(url, username, password)
      self[url] = AuthCredential.new(username: username, password: password)
    end

    # Returns the base64 encoded authorization string for the URL
    # or `nil` if no authorization exists.
    def for_url(url)
      if auth = self[url]
        Base64.encode("#{auth.username}#{auth.password}")
      end
    end

    # Clear the contents of the auth store.
    def clear!
      @credentials.clear!
      self
    end

    # Size of the current auth store (number of URL paths stored)
    def size
      @credentials.values.reduce(0) { |acc, paths| acc + paths.size }
    end

    # Inspect the auth store
    def inspect
      "<#{self.class}: #{@credentials.inspect}>"
    end

    # Creates a auth key based on the URL
    private def key_for(url)
      {url.scheme, url.host, url.port}
    end
  end
end
