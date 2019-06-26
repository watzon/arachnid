require "uri"

module Arachnid
  # Parses robots.txt files for the perusal of a single user-agent.
  #
  # The behaviour implemented is guided by the following sources, though
  # as there is no widely accepted standard, it may differ from other implementations.
  # If you consider its behaviour to be in error, please contact the author.
  #
  # http://www.robotstxt.org/orig.html
  #  - the original, now imprecise and outdated version
  # http://www.robotstxt.org/norobots-rfc.txt
  #  - a much more precise, outdated version
  # http://www.google.com/support/webmasters/bin/answer.py?hl=en&answer=156449&from=35237
  #  - a few hints at modern protocol extensions.
  #
  # This parser only considers lines starting with (case-insensitively:)
  #  Useragent: User-agent: Allow: Disallow: Sitemap:
  #
  # The file is divided into sections, each of which contains one or more User-agent:
  # lines, followed by one or more Allow: or Disallow: rules.
  #
  # The first section that contains a User-agent: line that matches the robot's
  # user-agent, is the only section that relevent to that robot. The sections are checked
  # in the same order as they appear in the file.
  #
  # (The * character is taken to mean "any number of any characters" during matching of
  #  user-agents)
  #
  # Within that section, the first Allow: or Disallow: rule that matches the expression
  # is taken as authoritative. If no rule in a section matches, the access is Allowed.
  #
  # (The order of matching is as in the RFC, Google matches all Allows and then all Disallows,
  #  while Bing matches the most specific rule, I'm sure there are other interpretations)
  #
  # When matching urls, all % encodings are normalised (except for /?=& which have meaning)
  # and "*"s match any number of any character.
  #
  # If a pattern ends with a $, then the pattern must match the entire path, or the entire
  # path with query string.
  #
  # TODO: Rework to allow for multiple Robots
  class Robots
    alias Rule = Tuple(String, Bool)
    alias RuleSet = Tuple(String, Array(Rule))

    getter body : String

    getter user_agent : String

    getter rules : Array(Tuple(String, Array(Rule)))

    getter sitemaps : Array(String)

    def initialize(@body : String, @user_agent : String)
      @sitemaps = [] of String
      @rules = [] of RuleSet
      parse(@body)
    end

    # Given a URI object, or a string representing one, determine whether this
    # robots.txt would allow access to the path.
    def allowed?(uri)
      uri = URI.parse(uri)
      path = (uri.path || "/") + (uri.query ? "?" + uri.query.to_s : "")
      path_allowed?(@user_agent, path)
    end

    # Check whether the relative path (a string of the url's path and query
    # string) is allowed by the rules we have for the given user_agent.
    #
    private def path_allowed?(user_agent, path)
      @rules.each do |(ua_glob, path_globs)|
        if match_ua_glob user_agent, ua_glob
          path_globs.each do |(path_glob, allowed)|
            return allowed if match_path_glob path, path_glob
          end
          return true
        end
      end
      true
    end

    # This does a case-insensitive substring match such that if the user agent
    # is contained within the glob, or vice-versa, we will match.
    #
    # According to the standard, *s shouldn't appear in the user-agent field
    # except in the case of "*" meaning all user agents. Google however imply
    # that the * will work, at least at the end of a string.
    #
    # For consistency, and because it seems expected behaviour, and because
    # a glob * will match a literal * we use glob matching not string matching.
    #
    # The standard also advocates a substring match of the robot's user-agent
    # within the user-agent field. From observation, it seems much more likely
    # that the match will be the other way about, though we check for both.
    #
    private def match_ua_glob(user_agent, glob)
      glob =~ Regex.new(Regex.escape(user_agent), Regex::Options::IGNORE_CASE) ||
        user_agent =~ Regex.new(reify(glob), Regex::Options::IGNORE_CASE)
    end

    # This does case-sensitive prefix matching, such that if the path starts
    # with the glob, we will match.
    #
    # According to the standard, that's it. However, it seems reasonably common
    # for asterkisks to be interpreted as though they were globs.
    #
    # Additionally, some search engines, like Google, will treat a trailing $
    # sign as forcing the glob to match the entire path - whether including
    # or excluding the query string is not clear, so we check both.
    #
    # (i.e. it seems likely that a site owner who has Disallow: *.pdf$ expects
    # to disallow requests to *.pdf?i_can_haz_pdf, which the robot could, if
    # it were feeling malicious, construe.)
    #
    # With URLs there is the additional complication that %-encoding can give
    # multiple representations for identical URLs, this is handled by
    # normalize_percent_encoding.
    #
    private def match_path_glob(path, glob)
      if glob =~ /\$$/
        end_marker = "(?:\?|$)"
        glob = glob.gsub /\$$/, ""
      else
        end_marker = ""
      end

      glob = normalize_percent_encoding(glob)
      path = normalize_percent_encoding(path)

      path =~ Regex.new("^" + reify(glob) + end_marker)

    rescue e
      false
    end

    # As a general rule, we want to ignore different representations of the
    # same URL. Naively we could just unescape, or escape, everything, however
    # the standard implies that a / is a HTTP path separator, while a %2F is an
    # encoded / that does not act as a path separator. Similar issues with ?, &
    # and =, though all other characters are fine. (While : also has a special
    # meaning in HTTP, most implementations ignore this in the path)
    #
    # It's also worth noting that %-encoding is case-insensitive, so we
    # explicitly upcase the few that we want to keep.
    #
    private def normalize_percent_encoding(path)
      # First double-escape any characters we don't want to unescape
      #                   &  /  =  ?
      path = path.gsub(/%(26|2F|3D|3F)/i) do |code|
        "%25#{code.upcase}"
      end

      URI.unescape(path)
    end

    # Convert the asterisks in a glob into (.*)s for regular expressions,
    # and at the same time, escape any other characters that would have
    # a significance in a regex.
    #
    private def reify(glob)
      glob.split("*").map { |part| Regex.escape(part) }.join(".*")
    end

    # Convert the @body into a set of @rules so that our parsing mechanism
    # becomes easier.
    #
    # @rules is an array of pairs. The first in the pair is the glob for the
    # user-agent and the second another array of pairs. The first of the new
    # pair is a glob for the path, and the second whether it appears in an
    # Allow: or a Disallow: rule.
    #
    # For example:
    #
    # User-agent: *
    # Disallow: /secret/
    # Allow: /     # allow everything...
    #
    # Would be parsed so that:
    #
    # @rules = [["*", [ ["/secret/", false], ["/", true] ]]]
    #
    #
    # The order of the arrays is maintained so that the first match in the file
    # is obeyed as indicated by the pseudo-RFC on http://robotstxt.org/. There
    # are alternative interpretations, some parse by speicifity of glob, and
    # some check Allow lines for any match before Disallow lines. All are
    # justifiable, but we could only pick one.
    #
    # Note that a blank Disallow: should be treated as an Allow: * and multiple
    # user-agents may share the same set of rules.
    #
    private def parse(body)
      body.split(/[\r\n]+/).each do |line|
        prefix, value = line.delete("\000").split(":", 2).map(&.strip)
        value = value.sub /\s+#.*/, "" if value
        parser_mode = :begin

        if prefix && value
          case prefix.downcase
          when /^user-?agent$/
            if parser_mode == :user_agent
              @rules << {value, rules.last[1]}
            else
              parser_mode = :user_agent
              @rules << {value, [] of Rule}
            end
          when "disallow"
            parser_mode = :rules
            @rules << {"*", [] of Rule} if @rules.empty?

            if value == ""
              @rules.last[1] << {"*", true}
            else
              @rules.last[1] << {value, false}
            end
          when "allow"
            parser_mode = :rules
            @rules << {"*", [] of Rule} if @rules.empty?
            @rules.last[1] << {value, true}
          when "sitemap"
            @sitemaps << value
          else
            # Ignore comments, Crawl-delay: and badly formed lines.
          end
        end
      end
    end
  end
end
