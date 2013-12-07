require 'semantic'

module Semantic

  # @note Semantic::Version subclasses Numeric so that it has sane Range
  #       semantics in Ruby 1.9+.
  class Version < Numeric

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

    private
    class ValidationFailure < ArgumentError; end
    def self.failure(message); ValidationFailure.new(message); end
  end
end
