require 'semantic'

module Semantic

  # @note Semantic::Version subclasses Numeric so that it has sane Range
  #       semantics in Ruby 1.9+.
  class Version < Numeric
    include Comparable

    # Parse a semantic version string.
    #
    # @param ver [String] the version string to parse
    # @return [Semantic::Version] a comparable Version object
    def self.parse(ver)
      _, major, minor, patch = *ver.match(/\A(\d+)\.(\d+)\.(\d+)(?:[-+]|\Z)/)
      raise failure 'Version numbers MUST begin with X.Y.Z' if major.nil?

      if [major, minor, patch].any? { |x| x =~ /^0\d+/ }
        raise failure 'Version numbers MUST NOT contain leading zeroes'
      end

      _, prerelease = *ver.match(/\A[0-9.]+[-](.*?)(?:[+]|\Z)/)
      if prerelease
        prerelease = prerelease.split('.', -1)

        if prerelease.empty? or prerelease.any? { |x| x.empty? }
          raise failure('Prerelease identifiers MUST NOT be empty')
        end

        if prerelease.any? { |x| x =~ /[^0-9a-zA-Z-]/ }
          message = 'Prerelease identifiers MUST use only ASCII ' +
                    'alphanumerics and hyphens'
          raise failure(message)
        end

        if prerelease.any? { |x| x =~ /^0\d+$/ }
          raise failure 'Prerelease identifiers MUST NOT contain leading zeroes'
        end

        prerelease.map! { |x| x =~ /^\d+$/ ? x.to_i : x }
      end

      _, build = *ver.match(/\A.*?[+](.*?)\Z/)
      if build
        build = build.split('.', -1)

        if build.empty? or build.any? { |x| x.empty? }
          raise failure('Build identifiers MUST NOT be empty')
        end

        if build.any? { |x| x =~ /[^0-9a-zA-Z-]/ }
          message = 'Build identifiers MUST use only ASCII alphanumerics and ' +
                    'hyphens'
          raise failure(message)
        end
      end

      self.new(
        :major => major.to_i,
        :minor => minor.to_i,
        :patch => patch.to_i,
        :prerelease => prerelease,
        :build => build
      )
    end

    attr_accessor :major, :minor, :patch

    # @param parts [Hash] the decomposed version string
    def initialize(parts)
      @major = parts[:major]
      @minor = parts[:minor]
      @patch = parts[:patch]
      @prerelease = parts[:prerelease]
      @build = parts[:build]
    end

    def prerelease
      @prerelease && @prerelease.join('.')
    end

    def build
      @build && @build.join('.')
    end

    def <=>(other)
      return self.major <=> other.major unless self.major == other.major
      return self.minor <=> other.minor unless self.minor == other.minor
      return self.patch <=> other.patch unless self.patch == other.patch
      return compare_prerelease(other)
    end

    def to_s
      "#{major}.#{minor}.#{patch}" +
      (@prerelease ? "-" + prerelease : '') +
      (@build      ? "+" + build      : '')
    end

    private
    class ValidationFailure < ArgumentError; end
    def self.failure(message); ValidationFailure.new(message); end

    def compare_prerelease(other)
      # The absence of a prerelease yields a higher precedence.
      if self.prerelease == other.prerelease
        return 0
      elsif self.prerelease.nil?
        return 1
      elsif other.prerelease.nil?
        return -1
      end

      all_mine = @prerelease || []
      all_yours = other.instance_variable_get(:@prerelease) || []

      # Precedence is determined by comparing each dot separated identifier from
      # left to right...
      size = [all_mine.size, all_yours.size].max
      Array.new(size).zip(all_mine, all_yours) do |_, mine, yours|
        # ...until a difference is found.
        next if mine == yours

        # Numbers are compared numerically, strings are compared ASCIIbetically.
        if mine.class == yours.class
          return mine <=> yours

        # A larger set of pre-release fields has a higher precedence.
        elsif mine.nil?
          return -1
        elsif yours.nil?
          return 1

        # Numeric identifiers always have lower precedence than non-numeric.
        elsif mine.is_a? Numeric
          return -1
        elsif yours.is_a? Numeric
          return 1
        end
      end
    end
  end
end
