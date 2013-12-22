require 'semantic/dependency'
require 'set'

module Semantic
  module Dependency
    module GraphNode
      include Comparable

      def name
      end

      def satisfied_by?(node)
        raise 'Called abstract method #satisfied_by?'
      end

      # Determines whether the modules dependencies are satisfied by the known
      # releases.
      #
      # @return [Boolean] true if all dependencies are satisfied
      def satisfied?
        dependencies.none? { |_, v| v.empty? }
      end

      def children
        @_children ||= {}
      end

      def populate_children(nodes)
        if children.empty?
          nodes = nodes.select { |node| satisfied_by?(node) }
          nodes.each do |node|
            children[node.name] = node
            node.populate_children(nodes)
          end
          self.freeze
        end
      end

      def dependencies
        @_dependencies ||= Hash.new { |h, k| h[k] = SortedSet.new }
      end

      def dependency_names
        dependencies.keys
      end

      def << (nodes)
        Array(nodes).each do |node|
          next unless dependencies.key?(node.name)
          if satisfied_by?(node)
            dependencies[node.name] << node
          end
        end
      end

      def <=>(other)
        name <=> other.name
      end
    end
  end
end