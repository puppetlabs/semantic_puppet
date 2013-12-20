require 'semantic'

module Semantic
  class VersionRange < Range
    class << self
      # Parses a version range string into a comparable {VersionRange} instance.
      #
      # Currently parsed version range string may take any of the following:
      # forms:
      #
      # * Regular Semantic Version strings
      #   * ex. `"1.0.0"`, `"1.2.3-pre"`
      # * Partial Semantic Version strings
      #   * ex. `"1.0.x"`, `"1.2"`, `"2.*"`
      # * Inequalities
      #   * ex. `"> 1.0.0"`, `"<3.2"`, `">=4"`
      # * Approximate Versions
      #   * ex. `"~1.0.0"`, `"~ 3.2"`, `"~4"`
      # * Inclusive Ranges
      #   * ex. `"1.0.0 - 1.3.9"`, `"1 - 2.3"`
      # * Range Intersections
      #   * ex. `">1.0.0 <=2.3"`
      #
      # @param range_str [String] the version range string to parse
      # @return [VersionRange] a new {VersionRange} instance
      def parse(range_str)
        partial = '\d+(?:[.]\d+)?(?:[.][xX*]|[.]\d+(?:[-][0-9a-zA-Z-]*)?)?'

        range = range_str.gsub(/([><=~])[ ]/, '\1')

        return case range
        when /\A[=]?(#{partial})\Z/
          parse_loose_version_expression($1)
        when /\A([><][=]?)(#{partial})\Z/
          parse_inequality_expression($1, $2)
        when /\A~(#{partial})\Z/
          parse_reasonably_close_expression($1)
        when /\A(#{partial}) - (#{partial})\Z/
          parse_inclusive_range_expression($1, $2)
        when / /
          range.split(' ').map { |part| parse(part) }.inject { |a,b| a & b }
        else
          raise ArgumentError, "Unparsable version range: #{range_str.inspect}"
        end
      end

      private

      # Creates a new {VersionRange} from a "loose" description of a Semantic
      # Version number.
      #
      # @see .process_loose_expr
      #
      # @param expr [String] a "loose" version expression
      # @return [VersionRange] a version range representing `expr`
      def parse_loose_version_expression(expr)
        start, finish = process_loose_expr(expr)

        if start.stable?
          start = start.send(:first_prerelease)
        end

        if finish.stable?
          exclude = true
          finish = finish.send(:first_prerelease)
        end

        self.new(start, finish, exclude)
      end

      # Creates an open-ended version range from an inequality expression.
      #
      # @overload parse_inequality_expression('<', expr)
      #   {include:.parse_lt_expression}
      #
      # @overload parse_inequality_expression('<=', expr)
      #   {include:.parse_lte_expression}
      #
      # @overload parse_inequality_expression('>', expr)
      #   {include:.parse_gt_expression}
      #
      # @overload parse_inequality_expression('>=', expr)
      #   {include:.parse_gte_expression}
      #
      # @param comp ['<', '<=', '>', '>='] an inequality operator
      # @param expr [String] a "loose" version expression
      # @return [VersionRange] a range covering all versions in the inequality
      def parse_inequality_expression(comp, expr)
        case comp
        when '>'
          parse_gt_expression(expr)
        when '>='
          parse_gte_expression(expr)
        when '<'
          parse_lt_expression(expr)
        when '<='
          parse_lte_expression(expr)
        end
      end

      # Returns a range covering all versions greater than the given `expr`.
      #
      # @param expr [String] the version to be greater than
      # @return [VersionRange] a range covering all versions greater than the
      #         given `expr`
      def parse_gt_expression(expr)
        if expr =~ /^[^+]*-/
          start = Version.parse("#{expr}.0")
        else
          start = process_loose_expr(expr).last.send(:first_prerelease)
        end

        self.new(start, MAX_VERSION)
      end

      # Returns a range covering all versions greater than or equal to the given
      # `expr`.
      #
      # @param expr [String] the version to be greater than or equal to
      # @return [VersionRange] a range covering all versions greater than or
      #         equal to the given `expr`
      def parse_gte_expression(expr)
        if expr =~ /^[^+]*-/
          start = Version.parse(expr)
        else
          start = process_loose_expr(expr).first.send(:first_prerelease)
        end

        self.new(start, MAX_VERSION)
      end

      # Returns a range covering all versions less than the given `expr`.
      #
      # @param expr [String] the version to be less than
      # @return [VersionRange] a range covering all versions less than the
      #         given `expr`
      def parse_lt_expression(expr)
        if expr =~ /^[^+]*-/
          finish = Version.parse(expr)
        else
          finish = process_loose_expr(expr).first.send(:first_prerelease)
        end

        self.new(MIN_VERSION, finish, true)
      end

      # Returns a range covering all versions less than or equal to the given
      # `expr`.
      #
      # @param expr [String] the version to be less than or equal to
      # @return [VersionRange] a range covering all versions less than or equal
      #         to the given `expr`
      def parse_lte_expression(expr)
        if expr =~ /^[^+]*-/
          finish = Version.parse(expr)
        else
          finish = process_loose_expr(expr).last.send(:first_prerelease)
        end

        self.new(MIN_VERSION, finish)
      end

      # The "reasonably close" expression is used to designate ranges that have
      # a reasonable proximity to the given "loose" version number. These take
      # the form:
      #
      #     ~[Version]
      #
      # The general semantics of these expressions are that the given version
      # forms a lower bound for the range, and the upper bound is either the
      # next version number increment (at whatever precision the expression
      # provides) or the next stable version (in the case of a prerelease
      # version).
      #
      # @example "Reasonably close" major version
      #   "~1" # => (>=1.0.0 <2.0.0)
      # @example "Reasonably close" minor version
      #   "~1.2" # => (>=1.2.0 <1.3.0)
      # @example "Reasonably close" patch version
      #   "~1.2.3" # => (1.2.3)
      # @example "Reasonably close" prerelease version
      #   "~1.2.3-alpha" # => (>=1.2.3-alpha <1.2.4)
      #
      # @param expr [String] a "loose" expression to build the range around
      # @return [VersionRange] a "reasonably close" version range
      def parse_reasonably_close_expression(expr)
        parsed, succ = process_loose_expr(expr)

        if parsed.stable?
          parsed = parsed.send(:first_prerelease)
          succ = succ.send(:first_prerelease)
          self.new(parsed, succ, true)
        else
          self.new(parsed, Version.new(succ.major, succ.minor, succ.patch))
        end
      end

      # An "inclusive range" expression takes two version numbers (or partial
      # version numbers) and creates a range that covers all versions between
      # them. These take the form:
      #
      #     [Version] - [Version]
      #
      # @param start [String] a "loose" expresssion for the start of the range
      # @param finish [String] a "loose" expression for the end of the range
      # @return [VersionRange] a {VersionRange} covering `start` to `finish`
      def parse_inclusive_range_expression(start, finish)
        start, _ = process_loose_expr(start)
        _, finish = process_loose_expr(finish)
        start = start.send(:first_prerelease) if start.stable?
        finish = finish.send(:first_prerelease) if finish.stable?
        self.new(start, finish)
      end

      # A "loose expression" is one that takes the form of all or part of a
      # valid Semantic Version number. Particularly:
      #
      # * [Major].[Minor].[Patch]-[Prerelease]
      # * [Major].[Minor].[Patch]
      # * [Major].[Minor]
      # * [Major]
      #
      # Various placeholders are also permitted in "loose expressions"
      # (typically an 'x' or an asterisk).
      #
      # This method parses these expressions into a minimal and maximal version
      # number pair.
      #
      # @todo Stabilize whether the second value is inclusive or exclusive
      #
      # @param expr [String] a string containing a "loose" version expression
      # @return [(VersionNumber, VersionNumber)] a minimal and maximal
      #         version pair for the given expression
      def process_loose_expr(expr)
        case expr
        when /^(\d+)(?:[.][xX*])?$/
          expr = "#{$1}.0.0"
          arity = :major
        when /^(\d+[.]\d+)(?:[.][xX*])?$/
          expr = "#{$1}.0"
          arity = :minor
        when /^\d+[.]\d+[.]\d+$/
          arity = :patch
        end

        version = next_version = Version.parse(expr)

        if arity
          next_version = version.next(arity)
        end

        [ version, next_version ]
      end
    end

    # Computes the intersection of a pair of ranges. If the ranges have no
    # useful intersection, an empty range is returned.
    #
    # @param other [VersionRange] the range to intersect with
    # @return [VersionRange] the common subset
    def intersection(other)
      unless other.kind_of?(VersionRange)
        raise ArgumentError, "value must be a #{VersionRange}"
      end

      if self.begin < other.begin
        return other.intersection(self)
      end

      unless cover?(other.begin) || other.cover?(self.begin)
        return EMPTY_RANGE
      end

      endpoint = ends_before?(other) ? self : other
      self.class.new(self.begin, endpoint.end, endpoint.exclude_end?)
    end
    alias :& :intersection

    private
    # The lowest precedence Version possible
    MIN_VERSION = Version.new(0, 0, 0, []).freeze

    # The highest precedence Version possible
    MAX_VERSION = Version.new((1.0/0.0), 0, 0).freeze

    # Determines whether this {VersionRange} has an earlier endpoint than the
    # give `other` range.
    #
    # @param other [VersionRange] the range to compare against
    # @return [Boolean] true if the endpoint for this range is less than or
    #         equal to the endpoint of the `other` range.
    def ends_before?(other)
      self.end < other.end || (self.end == other.end && self.exclude_end?)
    end

    public

    # A range that matches no versions
    EMPTY_RANGE = VersionRange.new(MIN_VERSION, MIN_VERSION, true).freeze
  end
end
