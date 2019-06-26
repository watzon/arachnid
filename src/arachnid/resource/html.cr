require "../extensions/uri"

module Arachnid
  class Resource
    # TODO: Create enumerable methods for the methods that take a block
    module HTML
      # include Enumerable

      # The title of the HTML resource.
      def title
        if (node = at("//title"))
          node.inner_text
        end
      end

      # Enumerates over the meta-redirect links in the resource.
      def each_meta_redirect(&block : URI ->)
        if (html? && doc)
          search("//meta[@http-equiv and @content]").each do |node|
            if node["http-equiv"] =~ /refresh/i
              content = node["content"]

              if (redirect = content.match(/url=(\S+)$/))
                yield URI.parse(redirect[1])
              end
            end
          end
        end
      end

      # Returns a boolean indicating whether or not resource-level meta
      # redirects are present in this resource.
      def meta_redirect?
        !meta_redirects.empty?
      end

      # The meta-redirect links of the resource.
      def meta_redirects
        redirects = [] of URI
        each_meta_redirect { |r| redirects << r }
        redirects
      end

      # Enumerates over every HTTP or meta-redirect link in the resource.
      def each_redirect(&block : URI ->)
        if (locations = @response.headers.get?("Location"))
          # Location headers override any meta-refresh redirects in the HTML
          locations.each { |l| URI.parse(l) }
        else
          # check resource-level meta redirects if there isn't a location header
          each_meta_redirect(&block)
        end
      end

      # URLs that this document redirects to.
      def redirects_to
        each_redirect.to_a
      end

      # Enumerates over every `mailto:` link in the resource.
      def each_mailto(&block)
        if (html? && doc)
          doc.xpath_nodes("//a[starts-with(@href,'mailto:')]").each do |a|
            yield a["href"][7..-1]
          end
        end
      end

      # `mailto:` links in the resource.
      def mailtos
        each_mailto.to_a
      end

      # Enumerates over every link in the resource.
      def each_link(&block : URI ->)
        each_redirect(&block) if redirect?

        each_image(&block)

        each_script(&block)

        each_resource(&block)

        if html? && (d = doc)
          d.xpath_nodes("//a[@href]").each do |a|
            link = to_absolute(a["href"])
            yield link if link
          end

          d.xpath_nodes("//frame[@src]").each do |iframe|
            link = to_absolute(iframe["src"])
            yield link if link
          end

          d.xpath_nodes("//iframe[@src]").each do |iframe|
            link = to_absolute(iframe["src"])
            yield link if link
          end
        end
      end

      def each_script(&block : URI ->)
        if html? && (d = doc)
          d.xpath_nodes("//script[@src]").each do |script|
            url = to_absolute(script["src"])
            yield url if url
          end
        end
      end

      def each_resource(&block : URI ->)
        if html? && (d = doc)
          d.xpath_nodes("//link[@href]").each do |link|
            yield URI.parse(link["href"])
          end
        end
      end

      def each_image(&block : URI ->)
        if html? && (d = doc)
          d.xpath_nodes("//img[@src]").each do |img|
            url = to_absolute(img["src"])
            yield url if url
          end

          d.xpath_nodes("//img[@srcset]").each do |set|
            sources = set["srcset"].split(" ").map_with_index { |e, i| (i.zero? || i.even?) ? e : nil }.compact
            sources.each do |source|
              url = to_absolute(source)
              yield url if url
            end
          end
        end
      end

      def each_video(&block : URI ->)
        if html? && (d = doc)
          d.xpath_nodes("//video[@src]").each do |video|
            url = to_absolute(video["src"])
            yield url if url
          end

          d.xpath_nodes("//video/source[@src]").each do |source|
            url = to_absolute(source["src"])
            yield url if url
          end
        end
      end

      # The links from within the resource.
      def links
        links = [] of URI
        each_link { |link| links << link }
        links
      end

      # Enumerates over every URL in the resource.
      def each_url(&block : URI ->)
        each_link(&block) do |link|
          if (url = to_absolute(link))
            yield url
          end
        end
      end

      # ditto
      def each(&block)
        each_url { |url| yield url }
      end

      # Absolute URIs from within the resource.
      def urls
        urls = [] of URI
        each_url { |url| urls << link }
        urls
      end

      # Normalizes and expands a given link into a proper URI.
      def to_absolute(link)
        link = link.is_a?(URI) ? link : URI.parse(link)

        new_url = begin
          url.merge(link)
        rescue Exception
          return
        end

        if (!new_url.opaque?) && (path = new_url.path)
          # ensure that paths begin with a leading '/' for URI::FTP
          if (new_url.scheme == "ftp" && !path.starts_with?("/"))
            path.insert(0, "/")
          end

          # make sure the path does not contain any .. or . directories,
          # since URI::Generic#merge cannot normalize paths such as
          # "/stuff/../"
          new_url.path = URI.expand_path(path)
        end

        return new_url
      end
    end
  end
end
