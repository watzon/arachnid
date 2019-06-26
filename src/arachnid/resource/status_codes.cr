module Arachnid
  class Resource
    module StatusCodes
      # The response code from the resource.
      def code
        @response.status_code.to_i
      end

      # Determines if the response code is `200`.
      def ok?
        code == 200
      end

      # Determines if the response code is `308`.
      def timedout?
        code == 308
      end

      # Determines if the response code is `400`.
      def bad_request?
        code == 400
      end

      # Determines if the response code is `401`.
      def unauthorized?
        code == 401
      end

      # Determines if the response code is `403`.
      def forbidden?
        code == 403
      end

      # Determines if the response code is `404`.
      def missing?
        code == 404
      end

      # Determines if the response code is `500`.
      def had_internal_server_error?
        code == 500
      end

      # Determines if the response code is `300`, `301`, `302`, `303`
      # or `307`. Also checks for "soft" redirects added at the resource
      # level by a meta refresh tag.
      def redirect?
        case code
        when 300..303, 307
          true
        when 200
          meta_redirect?
        else
          false
        end
      end
    end
  end
end
