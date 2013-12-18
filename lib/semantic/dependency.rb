require 'semantic'

module Semantic
  module Dependency
    extend self

    autoload :ModuleRelease, 'semantic/dependency/module_release'
    autoload :Source, 'semantic/dependency/source'

    # @!group Sources

    # @return [Array<Source>] a frozen copy of the {Source} list
    def sources
      (@sources ||= []).dup.freeze
    end

    # Appends a new {Source} to the current list.
    # @param source [Source] the {Source} to add
    # @return [void]
    def add_source(source)
      sources
      @sources << source
      nil
    end

    # Clears the current list of {Source}s.
    # @return [void]
    def clear_sources
      sources
      @sources.clear
      nil
    end

    # @!endgroup

    # Fetches a graph of modules and their dependencies from the currently
    # configured list of {Source}s.
    #
    # @todo Return a specialized "Graph" object.
    # @todo Allow for external constraints to be added to the graph.
    # @see #sources
    # @see #add_source
    # @see #clear_sources
    #
    # @param modules [{ String => String }]
    # @return [ModuleRelease] the root of a dependency graph
    def query(modules)
      graph = Source::ROOT_CAUSE.create_release('', nil, modules)

      modules = fetch(graph)
      releases = modules.values.flatten << graph
      releases.each do |rel|
        rel.dependencies.each do |name|
          rel.satisfy_dependencies(modules[name])
        end
      end

      return graph
    end

    # Given a graph result from {#query}, this method will resolve the graph of
    # dependencies, if possible, into a flat list of the best suited modules. If
    # the dependency graph does not have a suitable resolution, this method will
    # raise an exception to that effect.
    #
    # @param graph [ModuleRelease] the root of a dependency graph
    # @return [Array<ModuleRelease>] the list of releases to act on
    def resolve(graph)
      catch :next do
        return walk(graph.depends_on)
      end
      raise Exception
    end

    private

    # Iterates over a changing set of dependencies in search of the best
    # solution available. Fitness is specified as meeting all the constraints
    # placed on it, being {ModuleRelease#satisfied? satisfied}, and having the
    # greatest version number (with stability being preferred over prereleases).
    #
    # @todo Traversal order is not presently guaranteed.
    #
    # @param dependencies [{ String => Array<ModuleRelease> }] the dependencies
    # @param considering [Array<ModuleRelease>] the set of releases being tested
    # @return [Array<ModuleRelease>] the list of releases to use, if successful
    def walk(dependencies, *considering)
      return considering if dependencies.empty?

      # Selecting a dependency from the collection...
      name, deps = dependencies.shift

      # ... (and stepping over it if we've seen it before) ...
      return walk(dependencies, *considering) unless (deps & considering).empty?

      # ... we'll iterate through the list of possible versions in order.
      preferred_releases(deps).reverse_each do |dep|
        catch :next do
          # After adding any new dependencies and imposing our own constraints
          # on existing dependencies, we'll mark ourselves as "under
          # consideration" and recurse.
          merged = dependencies.merge(dep.depends_on) { |_,a,b| a & b }

          # If all subsequent dependencies resolved well, the recursive call
          # will return a completed dependency list. If there were problems
          # resolving our dependencies, we'll catch `:next`, which will cause
          # us to move to the next possibility.
          return walk(merged, *considering, dep)
        end
      end

      # Once we've exhausted all of our possible versions, we know that our
      # last choice was unusable, so we'll unwind the stack and make a new
      # choice.
      throw :next
    end

    # Given a {ModuleRelease}, this method will iterate through the current
    # list of {Source}s to find the complete list of versions available for its
    # dependencies.
    #
    # @param release [ModuleRelease] the release to fetch details for
    # @return [{ String => [ModuleRelease] }] the fetched dependency information
    def fetch(release, cache = Hash.new { |h,k| h[k] = {} })
      release.dependencies.each do |mod|
        next if cache.key? mod
        releases = cache[mod]
        sources.each do |source|
          source.fetch(mod).each do |dependency|
            releases[dependency.version] ||= dependency
            fetch(dependency, cache)
          end
        end
      end

      return cache.inject({}) do |hash, (key, value)|
        hash[key] = value.values; hash
      end
    end

    # Given a list of potential releases, this method returns the most suitable
    # releases for exploration. Only {ModuleRelease#satisfied? satisfied}
    # releases are considered, and releases with stable versions are preferred.
    #
    # @param releases [Array<ModuleRelease>] a list of potential releases
    # @return [Array<ModuleRelease>] releases open for consideration
    def preferred_releases(releases)
      satisfied = releases.select { |x| x.satisfied? }

      if satisfied.any? { |x| x.version.stable? }
        return satisfied.select { |x| x.version.stable? }
      else
        return satisfied
      end
    end
  end
end
