require 'semantic/dependency'

module Semantic
  module Dependency
    class ModuleRelease
      include GraphNode

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

        constraints.keys.each { |key| add_dependency(key) }
      end

      def satisfied_by?(node)
        if @constraints.key? node.name
          @constraints[node.name] === node.version
        else
          false
        end
      end

      def <=>(other)
        [ name, version ] <=> [ other.name, other.version ]
      end

      def to_s
        "#<#{self.class} #{name}@#{version}>"
      end
    end
  end
end
