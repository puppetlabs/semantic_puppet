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

      # Constrains the named module to suitable releases, as determined by the
      # given block.
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
        @constraints["#{mod}"] << [ source, block ]
      end

      # Constrains graph solutions based on the given block.  Graph constraints
      # are used to describe fundamental truths about the tooling or module
      # system (e.g.: module names contain a namespace component which is
      # dropped during install, so module names must be unique excluding the
      # namespace).
      #
      # @example Ensuring a single source for all modules
      #     @graph.add_constraint('installed', mod.name) do |nodes|
      #       nodes.count { |node| node.source } == 1
      #     end
      #
      # @see #considering_solution?
      #
      # @param source [String, Symbol] a name describing the source of the
      #               constraint
      # @yieldparam nodes [Array<GraphNode>] the nodes to test the constraint
      #             against
      # @yieldreturn [Boolean] whether the node passed the constraint
      # @return [void]
      def add_graph_constraint(source, &block)
        @constraints[:graph] << [ source, block ]
      end

      # Checks the proposed solution (or partial solution) against the graph
      # constraints.
      #
      # @see #add_graph_constraint
      #
      # @return [Boolean] true if none of the graph constraints are violated
      def considering_solution?(solution)
        @constraints[:graph].all? { |_, check| check[solution] }
      end

      def satisfied_by?(node)
        if dependencies.key? node.name
          @constraints["#{node.name}"].all? { |_, check| check[node] }
        else
          false
        end
      end
    end
  end
end
