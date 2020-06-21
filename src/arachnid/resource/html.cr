module Arachnid
  class Resource
    # Represents a parsed HTML page
    class HTML < Resource
      @parser : Myhtml::Parser

      delegate :body, :body!, :head, :head!, :root, :root!, :html, :html!, :document!,
               :nodes, :css, :to_html, :to_pretty_html, :encoding, to: @parser

      def initialize(uri, response)
        super(uri, response)
        @parser = Myhtml::Parser.new(response.body, detect_encoding_from_meta: true)
      end

      def title
        titles = css("title")
        if titles.size > 0
          titles.first.inner_text
        else
          ""
        end
      end

      def each_meta_redirect(&block : URI ->)
        css("meta[http-equiv=\"refresh\"]").each do |tag|
          if content = tag.attribute_by("content")
            if (redirect = content.match(/url=(\S+)$/))
              uri = @uri.resolve(redirect[1])
              yield uri
            end
          end
        end
      end

      def meta_redirects
        redirects = [] of URI
        each_meta_redirect { |uri| redirects << uri }
        redirects
      end

      def meta_redirect?
        !meta_redirects.empty?
      end

      def each_redirect(&block : URI ->)
        redirects.each do |uri|
          block.call(uri)
        end
      end

      def redirects
        location = @response.headers.fetch("Location", nil)
        locations = [location].compact.map { |l| @uri.resolve(l) }
        locations + meta_redirects
      end

      def each_mailto(&block : String ->)
        css("a[href^=\"mailto:\"]").each do |tag|
          if content = tag.attribute_by("href")
            if match = content.match("mailto:(.*)")
              yield match[1]
            end
          end
        end
      end

      def mailtos
        mailtos = [] of String
        each_mailto { |uri| mailtos << uri }
        mailtos
      end

      def each_link(&block : URI ->)
        css("a").each do |tag|
          if href = tag.attribute_by("href")
            unless href.match(/^(javascript|mailto|tel)/)
              uri = @uri.resolve(href)
              block.call(uri) if uri.host
            end
          end
        end
      end

      def links
        links = [] of URI
        each_link { |uri| links << uri }
        links
      end

      def each_image(&block : URI ->)
        css("img").each do |tag|
          if src = tag.attribute_by("src")
            uri = @uri.resolve(src)
            yield uri
          end

          if srcset = tag.attribute_by("srcset")
            parts = srcset.split(",")
            parts.each do |set|
              url = set.split(/\s+/).first
              uri = @uri.resolve(url)
              yield uri
            end
          end
        end
      end

      def images
        images = [] of URI
        each_image { |uri| images << uri }
        images
      end

      def each_video(&block : URI ->)
        css("video, video source").each do |tag|
          if src = tag.attribute_by("src")
            uri = @uri.resolve(src)
            yield uri
          end
        end
      end

      def videos
        videos = [] of URI
        each_video { |uri| videos << uri }
        videos
      end

      def each_script(&block : URI ->)
        css("script").each do |tag|
          if src = tag.attribute_by("src")
            uri = @uri.resolve(src)
            yield uri
          end
        end
      end

      def scripts
        scripts = [] of URI
        each_script { |uri| scripts << uri }
        scripts
      end

      def each_resource(&block : URI ->)
        css("link").each do |tag|
          if href = tag.attribute_by("href")
            uri = @uri.resolve(href)
            yield uri
          end
        end
      end

      def resources
        resources = [] of URI
        each_resource { |uri| resources << uri }
        resources
      end

      def each_frame(&block : URI ->)
        css("frame").each do |tag|
          if src = tag.attribute_by("src")
            uri = @uri.resolve(src)
            yield uri
          end
        end
      end

      def frames
        frames = [] of URI
        each_frame { |uri| frames << uri }
        frames
      end

      def each_iframe(&block : URI ->)
        css("iframe").each do |tag|
          if src = tag.attribute_by("src")
            uri = @uri.resolve(src)
            yield uri
          end
        end
      end

      def iframes
        iframes = [] of URI
        each_iframe { |uri| iframes << uri }
        iframes
      end

      def each_url(&block : URI ->)
        urls.each do |uri|
          yield uri
        end
      end

      def urls
        links + redirects + images + videos + scripts + resources + frames + iframes
      end

      def save(path)
        File.write(path, @parser.to_pretty_html)
      end
    end
  end
end
