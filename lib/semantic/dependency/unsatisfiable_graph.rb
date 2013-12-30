require 'semantic/dependency'

module Semantic
  module Dependency
    class UnsatisfiableGraph < StandardError
      attr_reader :graph

      def initialize(graph)
        @graph = graph

        deps = graph.modules
        if deps.length == 2
          deps = [ deps.join(' and ') ]
        elsif deps.length > 2
          deps[-1] = "and #{deps.last}"
        end

        super "Could not find satisfying releases for #{deps.join(', ')}"
      end
    end
  end
end
