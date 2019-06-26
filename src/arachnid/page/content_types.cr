module Arachnid
  class Page
    module ContentTypes
      # The Content-Type of the page.
      def content_type
        @response.content_type || ""
      end

      # The content types of the page.
      def content_types
        types = @response.headers.get?("content-type") || [] of String
      end

      # The charset included in the Content-Type.
      def content_charset
        content_types.each do |value|
          if value.includes?(";")
            value.split(";").each do |param|
              param.strip!

              if param.starts_with?("charset=")
                return param.split("=", 2).last
              end
            end
          end
        end

        return nil
      end

      # Determines if any of the content-types of the page include a given
      # type.
      def is_content_type?(type : String | Regex)
        content_types.any? do |value|
          value = value.split(";", 2).first

          if type.is_a?(Regex)
            value =~ type
          else
            value == type
          end
        end
      end

      # Determines if the page is plain-text.
      def plain_text?
        is_content_type?("text/plain")
      end

      # ditto
      def text?
        plain_text?
      end

      # Determines if the page is a Directory Listing.
      def directory?
        is_content_type?("text/directory")
      end

      # Determines if the page is HTML document.
      def html?
        is_content_type?("text/html")
      end

      # Determines if the page is XML document.
      def xml?
        is_content_type?(/(text|application)\/xml/)
      end

      # Determines if the page is XML Stylesheet (XSL).
      def xsl?
        is_content_type?("text/xsl")
      end

      # Determines if the page is JavaScript.
      def javascript?
        is_content_type?(/(text|application)\/javascript/)
      end

      # Determines if the page is JSON.
      def json?
        is_content_type?("application/json")
      end

      # Determines if the page is a CSS stylesheet.
      def css?
        is_content_type?("text/css")
      end

      # Determines if the page is a RSS feed.
      def rss?
        is_content_type?(/application\/(rss\+xml|rdf\+xml)/)
      end

      # Determines if the page is an Atom feed.
      def atom?
        is_content_type?("application/atom+xml")
      end

      # Determines if the page is a MS Word document.
      def ms_word?
        is_content_type?("application/msword")
      end

      # Determines if the page is a PDF document.
      def pdf?
        is_content_type?("application/pdf")
      end

      # Determines if the page is a ZIP archive.
      def zip?
        is_content_type?("application/zip")
      end

      # Determine if the page is an image.
      def image?
        is_content_type?(/image\//)
      end

      def png?
        is_content_type?("image/png")
      end

      def gif?
        is_content_type?("image/gif")
      end

      def jpg?
        is_content_type?(/image\/(jpg|jpeg)/)
      end

      def svg?
        is_content_type?(/image\/svg(\+xml)?/)
      end

      def video?
        is_content_type?(/video\/.*/)
      end

      def mp4?
        is_content_type?("video/mp4")
      end

      def avi?
        is_content_type?("video/x-msvideo")
      end

      def wmv?
        is_content_type?("video/x-ms-wmv")
      end

      def quicktime?
        is_content_type?("video/quicktime")
      end

      def flash?
        is_content_type?("video/flash") ||
          is_content_type?("application/x-shockwave-flash")
      end
    end
  end
end
