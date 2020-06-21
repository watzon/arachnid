class URI
  def split_path(path)
    path.split("/")
  end

  def merge_path(base, rel)

    # RFC2396, Section 5.2, 5)
    # RFC2396, Section 5.2, 6)
    base_path = split_path(base)
    rel_path  = split_path(rel)

    # RFC2396, Section 5.2, 6), a)
    base_path << "" if base_path.last == ".."
    while i = base_path.index("..")
      base_path = base_path[i - 1, 2]
    end

    if (first = rel_path.first) && first.empty?
      base_path.clear
      rel_path.shift
    end

    # RFC2396, Section 5.2, 6), c)
    # RFC2396, Section 5.2, 6), d)
    rel_path.push("") if rel_path.last == '.' || rel_path.last == ".."
    rel_path.delete('.')

    # RFC2396, Section 5.2, 6), e)
    tmp = [] of String
    rel_path.each do |x|
      if x == ".." &&
          !(tmp.empty? || tmp.last == "..")
        tmp.pop
      else
        tmp << x
      end
    end

    add_trailer_slash = !tmp.empty?
    if base_path.empty?
      base_path = [""] # keep '/' for root directory
    elsif add_trailer_slash
      base_path.pop
    end
    while x = tmp.shift
      if x == ".."
        # RFC2396, Section 4
        # a .. or . in an absolute path has no special meaning
        base_path.pop if base_path.size > 1
      else
        # if x == ".."
        #   valid absolute (but abnormal) path "/../..."
        # else
        #   valid absolute path
        # end
        base_path << x
        tmp.each {|t| base_path << t}
        add_trailer_slash = false
        break
      end
    end
    base_path.push("") if add_trailer_slash

    return base_path.join('/')
  end

  def merge(oth)
    oth = URI.parse(oth) unless oth.is_a?(URI)

    if oth.absolute?
      # raise BadURIError, "both URI are absolute" if absolute?
      # hmm... should return oth for usability?
      return oth
    end

    unless self.absolute?
      raise URI::Error.new("both URI are othative")
    end

    base = self.dup

    authority = oth.userinfo || oth.host || oth.port

    # RFC2396, Section 5.2, 2)
    if (oth.path.nil? || oth.path.empty?) && !authority && !oth.query
      base.fragment=(oth.fragment) if oth.fragment
      return base
    end

    base.query = nil
    base.fragment=(nil)

    # RFC2396, Section 5.2, 4)
    if !authority
      base.path = merge_path(base.path, oth.path) if base.path && oth.path
    else
      # RFC2396, Section 5.2, 4)
      base.path = oth.path if oth.path
    end

    # RFC2396, Section 5.2, 7)
    base.user = oth.userinfo if oth.userinfo
    base.host = oth.host if oth.host
    base.port = oth.port if oth.port
    base.query = oth.query if oth.query
    base.fragment=(oth.fragment) if oth.fragment

    return base
  end
end
