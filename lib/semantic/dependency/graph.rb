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

        modules.each do |name, range|
          add_constraint('initialize', name, range.to_s) do |node|
            range === node.version
          end

          add_dependency(name)
        end
      end

      def constraints_for(mod)
        return [] unless @constraints.has_key?(mod)

        @constraints[mod].map do |constraint|
          {
            :source      => constraint[0],
            :description => constraint[1],
            :test        => constraint[2],
          }
        end
      end

      # Constrains the named module to suitable releases, as determined by the
      # given block.
      #
      # @example Version-locking currently installed modules
      #     installed_modules.each do |m|
      #       @graph.add_constraint('installed', m.name, m.version) do |node|
      #         m.version == node.version
      #       end
      #     end
      #
      # @param source [String, Symbol] a name describing the source of the
      #               constraint
      # @param mod [String] the name of the module
      # @param desc [String] a description of the enforced constraint
      # @yieldparam node [GraphNode] the node to test the constraint against
      # @yieldreturn [Boolean] whether the node passed the constraint
      # @return [void]
      def add_constraint(source, mod, desc, &block)
        @constraints["#{mod}"] << [ source, desc, block ]
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

      # Checks the proposed solution (or partial solution) against the graph's
      # constraints.
      #
      # @see #add_graph_constraint
      #
      # @return [Boolean] true if none of the graph constraints are violated
      def considering_solution?(solution)
        constrained = solution.select do |node|
          @constraints.key?("#{node.name}")
        end

        @constraints[:graph].all? { |_, check| check[solution] } &&
        constrained.all? do |node|
          constraints_for("#{node.name}").all? { |x| x[:test][node] }
        end
      end

      def satisfied_by?(node)
        if dependencies.key? node.name
          constraints_for("#{node.name}").all? { |x| x[:test][node] }
        else
          false
        end
      end
    end
  end
end
