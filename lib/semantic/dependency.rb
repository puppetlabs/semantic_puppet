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

    def walk(dependencies, considering = [])
      pair = dependencies.shift
      name = pair.first
      deps = pair.last
      return considering if name.nil?

      prefer_stable_releases(deps).reverse_each do |dep|
        next unless dep.satisfied?

        new_dependencies = dependencies.merge(dep.depends_on) do |k, v1, v2|
          new_deps = v1 & v2
          throw :next if new_deps.empty?
          new_deps
        end
        catch(:next) do
          considering = walk(new_dependencies, considering + [dep])
        end
        return considering
      end

      throw :next
    end

    private

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

    def prefer_stable_releases(releases)
      stable = proc { |x| x.version.prerelease.nil? }

      if releases.none?(&stable)
        return releases
      else
        return releases.select(&stable)
      end
    end
  end
end
