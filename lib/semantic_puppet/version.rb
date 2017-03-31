require 'semantic_puppet'

module SemanticPuppet
  # @note SemanticPuppet::Version subclasses Numeric so that it has sane Range
  #       semantics in Ruby 1.9+.
  class Version < Numeric
    include Comparable

    class ValidationFailure < ArgumentError; end

    # Parse a Semantic Version string.
    #
    # @param ver [String] the version string to parse
    # @return [Version] a comparable {Version} object
    def self.parse(ver)
      match, major, minor, patch, prerelease, build = *ver.match(REGEX_FULL_RX)

      raise ValidationFailure, _("Unable to parse '%{version}' as a semantic version identifier") % {version: ver} unless match

      new(major.to_i, minor.to_i, patch.to_i, parse_prerelease(prerelease), parse_build(build)).freeze
    end

    # Validate a Semantic Version string.
    #
    # @param ver [String] the version string to validate
    # @return [bool] whether or not the string represents a valid Semantic Version
    def self.valid?(ver)
      match = ver.match(REGEX_FULL_RX)
      if match.nil?
        false
      else
        prerelease = match[4]
        prerelease.nil? || prerelease.split('.').all? { |x| !(x =~ /^0\d+/) }
      end
    end

    def self.parse_build(build)
      build.nil? ? nil : build.split('.').freeze
    end

    def self.parse_prerelease(prerelease)
      return nil unless prerelease
      prerelease.split('.').map do |x|
        if x =~ /^\d+$/
          raise ValidationFailure, _('Numeric pre-release identifiers MUST NOT contain leading zeroes') if x.length > 1 && x.start_with?('0')
          x.to_i
        else
          x
        end
      end.freeze
    end

    attr_reader :major, :minor, :patch

    def initialize(major, minor, patch, prerelease = nil, build = nil)
      @major      = major
      @minor      = minor
      @patch      = patch
      @prerelease = prerelease
      @build      = build
    end

    def next(part)
      case part
      when :major
        self.class.new(@major.next, 0, 0)
      when :minor
        self.class.new(@major, @minor.next, 0)
      when :patch
        self.class.new(@major, @minor, @patch.next)
      end
    end

    def prerelease
      @prerelease.nil? || @prerelease.empty? ? nil : @prerelease.join('.')
    end

    # @return [Boolean] true if this is a stable release
    def stable?
      @prerelease.nil? || @prerelease.empty?
    end

    def build
      @build.nil? || @build.empty? ? nil : @build.join('.')
    end

    def <=>(other)
      return nil unless other.is_a?(Version)
      cmp = @major <=> other.major
      if cmp == 0
        cmp = @minor <=> other.minor
        if cmp == 0
          cmp = @patch <=> other.patch
          if cmp == 0
            cmp = compare_prerelease(other)
          end
        end
      end
      cmp
    end

    def eql?(other)
      other.is_a?(Version) &&
        @major.eql?(other.major) &&
        @minor.eql?(other.minor) &&
        @patch.eql?(other.patch) &&
        @prerelease.eql?(other.instance_variable_get(:@prerelease)) &&
        @build.eql?(other.instance_variable_get(:@build))
    end
    alias == eql?

    def to_s
      s = "#{@major}.#{@minor}.#{@patch}"
      unless @prerelease.nil? || @prerelease.empty?
        s << '-'
        @prerelease.each { |p| s << p.to_s << '.' }
        s.chomp!('.')
      end
      unless @build.nil? || @build.empty?
        s << '+'
        @build.each { |p| s << p.to_s << '.' }
        s.chomp!('.')
      end
      s
    end
    alias inspect to_s

    def hash
      (((((@major * 0x100) ^ @minor) * 0x100) ^ @patch) * 0x100) ^ @prerelease.hash
    end

    def compare_prerelease(other)
      mine = @prerelease
      yours = other.instance_variable_get(:@prerelease)
      if mine.nil?
        yours.nil? ? 0 : 1
      elsif yours.nil?
        -1
      else
        your_max = yours.size
        mine.each_with_index do |x, idx|
          return 1 if idx >= your_max
          y = yours[idx]
          cmp = if x.is_a?(Integer)
            y.is_a?(Integer) ? x <=> y : -1
          elsif y.is_a?(Integer)
            1
          else
            x <=> y
          end
          return cmp unless cmp == 0
        end
        mine.size <=> your_max
      end
    end

    def first_prerelease
      self.class.new(@major, @minor, @patch, [])
    end

    # Version string matching regexes
    REGEX_NUMERIC = '(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'.freeze # Major . Minor . Patch
    REGEX_PRE     = '(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?'.freeze    # Prerelease
    REGEX_BUILD   = '(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?'.freeze  # Build
    REGEX_FULL    = REGEX_NUMERIC + REGEX_PRE + REGEX_BUILD.freeze
    REGEX_FULL_RX = /\A#{REGEX_FULL}\Z/.freeze

    # The lowest precedence Version possible
    MIN = self.new(0, 0, 0, [].freeze).freeze

    # The highest precedence Version possible
    MAX = self.new(Float::INFINITY, 0, 0).freeze
  end
end
