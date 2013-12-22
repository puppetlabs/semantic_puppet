require 'semantic/dependency'

module Semantic
  module Dependency
    class Graph
      include GraphNode

      attr_reader :modules, :constraints

      # Create a new instance of a dependency graph.
      #
      # @param modules [{String => VersionRange}] the required module
      #        set and their version constraints
      def initialize(modules = {})
        @modules     = modules.keys
        @constraints = Hash.new { |h, k| h[k] = [] }

        modules.each do |key, range|
          add_constraint('initialize', key) { |node| range === node.version }
          add_dependency(key)
        end
      end

      # Constrains the module to suitable releases, as determined by the given
      # `constraint`.
      #
      # @example Version-locking currently installed modules
      #     installed_modules.each do |mod|
      #       @graph.add_constraint('installed', mod.name) do |node|
      #         mod.version == node.version
      #       end
      #     end
      #
      # @param source [String, Symbol] a name describing the source of the
      #               constraint
      # @param mod [String] the name of the module
      # @yieldparam node [GraphNode] the node to test the constraint against
      # @yieldreturn [Boolean] whether the node passed the constraint
      # @return [void]
      def add_constraint(source, mod, &block)
        @constraints[mod] << [ source, block ]
      end

      def satisfied_by?(node)
        if dependencies.key? node.name
          @constraints[node.name].all? { |_, check| check[node] }
        else
          false
        end
      end
    end
  end
end
