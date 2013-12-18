require 'semantic'

module Semantic
  class VersionRange < Range
    class << self
      # @todo Ensure that set of version ranges overlaps with https://github.com/puppetlabs/puppet/blob/master/lib/semver.rb#L24
      def parse(range)
        partial = '\d+(?:[.]\d+)?(?:[.][xX*]|[.]\d+(?:[-][0-9a-zA-Z-]*)?)?'

        return case range
        when /\A(\d+)[.](\d+)[.](\d+)(?:[-][0-9a-zA-Z-]*)?\Z/
          parse_version_expression(range)
        when /\A(\d+)[.](\d+)(?:[.][xX*])?\Z/
          parse_major_minor_expression($1, $2)
        when /\A(\d+)(?:[.][xX*])?\Z/
          parse_major_version_expression($1)
        when /\A([><][=]?)[ ]?(#{partial})\Z/
          parse_open_ended_expression($1, $2)
        when /\A~(#{partial})\Z/
          parse_reasonably_close_expression($1)
        when /\A(#{partial}) - (#{partial})\Z/
          parse_inclusive_range_expression($1, $2)
        when / /
          range.split(' ').map { |part| parse(part) }.inject { |a,b| a & b }
        end
      end

      private

      def parse_version_expression(range)
        start = finish = Version.parse(range)
        start = start.send(:first_prerelease) if start.stable?
        self.new(start, finish)
      end

      def parse_major_minor_expression(major, minor)
        start = Version.parse("#{major}.#{minor}.0").send(:first_prerelease)
        finish = start.next(:minor).send(:first_prerelease)
        self.new(start, finish, true)
      end

      def parse_major_version_expression(major)
        start = Version.parse("#{major}.0.0").send(:first_prerelease)
        finish = start.next(:major).send(:first_prerelease)
        self.new(start, finish, true)
      end

      def parse_open_ended_expression(comp, expr)
        start = MIN_VERSION
        finish = MAX_VERSION

        parsed, succ = parse_loose_expr(expr)

        case comp
        when '>'
          start = succ
          start = start.send(:first_prerelease) if start.stable?
        when '>='
          start = parsed
          start = start.send(:first_prerelease) if start.stable?
        when '<'
          finish = parsed
          finish = finish.send(:first_prerelease) if finish.stable?
        when '<='
          finish = succ
          finish = finish.send(:first_prerelease) if finish.stable?
        end

        self.new(start, finish, true)
      end

      def parse_reasonably_close_expression(expr)
        parsed, succ = parse_loose_expr(expr)

        if parsed.stable?
          parsed = parsed.send(:first_prerelease)
          succ = succ.send(:first_prerelease)
          self.new(parsed, succ, true)
        else
          self.new(parsed, Version.new(succ.major, succ.minor, succ.patch))
        end
      end

      def parse_inclusive_range_expression(start, finish)
        start, _ = parse_loose_expr(start)
        _, finish = parse_loose_expr(finish)
        start = start.send(:first_prerelease) if start.stable?
        finish = finish.send(:first_prerelease) if finish.stable?
        self.new(start, finish, true)
      end

      def parse_loose_expr(expr)
        case expr
        when /^\d+(?:[.][xX*])?$/
          expr += '.0.0'
          arity = :major
        when /^\d+[.]\d+(?:[.][xX*])?$/
          expr += '.0'
          arity = :minor
        when /^\d+[.]\d+[.]\d+$/
          arity = :patch
        else
          arity = :prerelease
        end

        [ Version.parse(expr), Version.parse(expr).next(arity) ]
      end

      # The lowest precedence Version possible
      MIN_VERSION = Version.new(0, 0, 0, []).freeze

      # The highest precedence Version possible
      MAX_VERSION = Version.new((1.0/0.0), 0, 0).freeze
    end

    # A range that matches no versions
    EMPTY_RANGE = VersionRange.new(Version.parse('0.0.0'), Version.parse('0.0.0'), true).freeze

    # Computes the intersection of a pair of ranges. If the ranges have no
    # useful intersection, an empty range is returned.
    #
    # @param other [Semantic::VersionRange] the range to intersect with
    # @return [Semantic::VersionRange] the intersected ranges
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

    def ends_before?(other)
      self.end < other.end || (self.end == other.end && self.exclude_end?)
    end
  end
end
