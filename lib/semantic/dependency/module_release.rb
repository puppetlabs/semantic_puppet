require 'semantic/dependency'

module Semantic
  module Dependency
    class ModuleRelease
      attr_reader :name, :version, :constraints

      # Create a new instance of a module release.
      #
      # @param source [Semantic::Dependency::Source]
      # @param name [String]
      # @param version [Semantic::Version]
      # @param constraints [{String => Semantic::VersionRange}]
      def initialize(source, name, version, constraints = {})
        @source      = source
        @name        = name.freeze
        @version     = version.freeze
        @constraints = constraints.freeze
        @refs        = Hash.new { |h, k| h[k] = [] }
      end

      # @return [Array(String)] the list of module dependencies
      def dependencies
        @constraints.keys
      end

      def depends_on
        @refs
      end

      # Marks this release's dependencies as satisified by the given releases,
      # as appropriate.
      #
      # @param releases [ModuleRelease, Array(ModuleRelease)] the releases to
      #        use for satisfying dependencies
      # @return [void]
      def satisfy_dependencies(releases)
        Array(releases).each do |release|
          dep_name = release.name
          if @constraints.key?(dep_name)
            if @constraints[dep_name].include?(release.version)
              @refs[release.name] << release
              @refs[release.name].uniq! { |rel| rel.version }
              @refs[release.name].sort_by! { |rel| rel.version }
            end
          end
        end
      end

      # Determines whether the modules dependencies are satisfied by the known
      # releases.
      #
      # @return [Boolean] true if all dependencies are satisfied
      def satisfied?
        dependencies.all? { |x| @refs.key?(x) }
      end

      # def install(path)
      #   @source.install(self, path)
      # end

      def to_s
        "#<#{self.class} #{name}@#{version}>"
      end
    end
  end
end
