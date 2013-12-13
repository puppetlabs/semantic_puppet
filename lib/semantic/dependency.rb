require 'semantic'

module Semantic
  module Dependency
    extend self

    autoload :ModuleRelease, 'semantic/dependency/module_release'
    autoload :Source, 'semantic/dependency/source'

    def sources
      (@sources ||= []).dup.freeze
    end

    def add_source(source)
      sources
      @sources << source
    end

    def clear_sources
      sources
      @sources.clear
    end

    # Fetches a graph of modules and their dependencies from the currently
    # configured list of {Source}s.
    #
    # @param modules [{ String => String }]
    # @see #sources
    # @see #add_source
    # @see #clear_sources
    def query(modules)
      release = Source::ROOT_CAUSE.create_release('', nil, modules)

      modules = fetch release
      releases = modules.values.flatten << release
      releases.each do |rel|
        rel.dependencies.each do |name|
          rel.satisfy_dependencies modules[name]
        end
      end

      return release
    end

    def resolve(graph)
      walk(graph.depends_on)
    end

    private

    # @param dependencies [{ String => Array(ModuleRelease) }] the dependencies
    # @param considering [Array(ModuleRelease)] the set of releases being tested
    def walk(dependencies, *considering)
      return considering if dependencies.empty?

      # Selecting a dependency from the collection...
      name, deps = dependencies.shift

      # ... we'll iterate through the list of possible versions in order.
      preferred_releases(deps).reverse_each do |dep|
        catch(:next) do
          # After adding any new dependencies and imposing our own constraints
          # on existing dependencies, we'll mark ourselves as "under
          # consideration" and recurse.
          merged = dependencies.merge(dep.depends_on) { |_,a,b| a & b }

          # If all subsequent dependencies resolved well, the recursive call
          # will return a completed dependency list. If there were problems
          # resolving our dependencies, we'll catch `:next`, which will cause
          # us to move to the next possibility.
          return walk(merged, dep, *considering)
        end
      end

      # Once we've exhausted all of our possible versions, we know that our
      # last choice was unusable, so we'll unwind the stack and make a new
      # choice.
      throw :next
    end

    # @param module [ModuleRelease] the release to detail
    def fetch(release, cache = Hash.new { |h,k| h[k] = {} })
      release.dependencies.each do |mod|
        next if cache.key? mod
        releases = cache[mod]
        sources.each do |source|
          source.fetch(mod).each do |dependency|
            releases[dependency.version] ||= dependency
            fetch dependency, cache
          end
        end
      end

      return cache.inject({}) do |hash, (key, value)|
        hash[key] = value.values; hash
      end
    end

    def preferred_releases(releases)
      stable = proc { |x| x.version.prerelease.nil? }

      if releases.none?(&stable)
        return releases.select { |r| r.satisfied? }
      else
        return releases.select(&stable).select { |r| r.satisfied? }
      end
    end
  end
end
