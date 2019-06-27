module Arachnid
  # The `Rules` class represents collections of acceptance and rejection
  # rules, which are used to filter data.
  class Rules(T)
    # Accept rules
    getter accept : Array(Proc(T | Nil, Bool) | T | Regex | String)

    # Reject rules
    getter reject : Array(Proc(T | Nil, Bool) | T | Regex | String)

    # Creates a new `Rules` object.
    def initialize(accept : Array(Proc(T | Nil, Bool) | T | Regex | String)? = nil, reject : Array(Proc(T | Nil, Bool) | T | Regex | String)? = nil)
      @accept = accept ? accept : [] of Proc(T | Nil, Bool) | T | Regex | String
      @reject = reject ? reject : [] of Proc(T | Nil, Bool) | T | Regex | String
    end

    # Determines whether the data should be accepted or rejected.
    def accept?(data : T)
      result = true
      result = @accept.any? { |rule| test_data(data, rule) } unless @accept.empty?
      result = !@reject.any? { |rule| test_data(data, rule) } unless @reject.empty? || result == false
      result
    end

    def accept=(value)
      @accept = value || [] of Proc(T | Nil, Bool) | T | Regex | String
    end

    # Determines whether the data should be rejected or accepted.
    def reject?(data : T)
      !accept?(data)
    end

    def reject=(value)
      @reject = value || [] of Proc(T | Nil, Bool) | T | Regex | String
    end

    # Tests the given data against a pattern.
    private def test_data(data : T, rule)
      case rule
      when Proc
        rule.call(data) == true
      when Regex
        !((data.to_s =~ rule).nil?)
      else
        data == rule
      end
    end
  end
end
