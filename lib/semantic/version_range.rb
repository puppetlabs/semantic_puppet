require 'semantic'

module Semantic
  class VersionRange < Range
    class << self
      # @todo Actually parse the set of version ranges described here https://github.com/mojombo/semver/issues/113#issuecomment-19347872
      # @todo Ensure that set of version ranges overlaps with https://github.com/puppetlabs/puppet/blob/master/lib/semver.rb#L24
      def parse(range)
        return case range
        when /\A(\d+)[.](\d+)[.](\d+)(?:[-][a-zA-Z0-9-]*)?\Z/
          parse_version_expression(range)
        when /\A(\d+)[.](\d+)(?:[.][xX*])?\Z/
          parse_major_minor_expression($1, $2)
        when /\A(\d+)(?:[.][xX*])?\Z/
          parse_major_version_expression($1)
        when /\A([><][=]?)[ ]?(\d+(?:[.]\d+)?(?:[.][xX*]|[.]\d+(?:[-][a-zA-Z0-9-]*)?)?)\Z/
          parse_open_ended_expression($1, $2)
        when /\A~(\d+(?:[.]\d+)?(?:[.][xX*]|[.]\d+(?:[-][a-zA-Z0-9-]*)?)?)\Z/
          parse_reasonably_close_expression($1)
        when /\A(\d+(?:[.]\d+)?(?:[.][xX*]|[.]\d+(?:[-][a-zA-Z0-9-]*)?)?) - (\d+(?:[.]\d+)?(?:[.][xX*]|[.]\d+(?:[-][a-zA-Z0-9-]*)?)?)\Z/
          parse_inclusive_range_expression($1, $2)
        end
      end

      private

      def parse_version_expression(range)
        start = finish = Version.parse(range)
        start = start.send(:first_prerelease) unless start.prerelease
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
          start = start.send(:first_prerelease) unless start.prerelease
        when '>='
          start = parsed
          start = start.send(:first_prerelease) unless start.prerelease
        when '<'
          finish = parsed
          finish = finish.send(:first_prerelease) unless finish.prerelease
        when '<='
          finish = succ
          finish = finish.send(:first_prerelease) unless finish.prerelease
        end

        self.new(start, finish, true)
      end

      def parse_reasonably_close_expression(expr)
        parsed, succ = parse_loose_expr(expr)

        if expr =~ /-/
          self.new(parsed, succ.next(:stable))
        else
          parsed = parsed.send(:first_prerelease)
          succ = succ.send(:first_prerelease)
          self.new(parsed, succ, true)
        end
      end

      def parse_inclusive_range_expression(start, finish)
        start, _ = parse_loose_expr(start)
        _, finish = parse_loose_expr(finish)
        start = start.send(:first_prerelease) unless start.prerelease
        finish = finish.send(:first_prerelease) unless finish.prerelease
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
  end
end
