require 'spec_helper'
require 'semantic/dependency'

describe Semantic::Dependency do
  def create_release(source, name, version, deps = {})
    Semantic::Dependency::ModuleRelease.new(
      source,
      name,
      Semantic::Version.parse(version),
      Hash[deps.map { |k, v| [k, Semantic::VersionRange.parse(v) ] }]
    )
  end

  describe '.sources' do
    it 'defaults to an empty list' do
      expect(subject.sources).to be_empty
    end

    it 'is frozen' do
      expect(subject.sources).to be_frozen
    end

    it 'can be modified by using #add_source' do
      subject.add_source(Semantic::Dependency::Source.new)
      expect(subject.sources).to_not be_empty
    end

    it 'can be emptied by using #clear_sources' do
      subject.add_source(Semantic::Dependency::Source.new)
      subject.clear_sources
      expect(subject.sources).to be_empty
    end
  end

  describe '.query' do
    context 'without sources' do
      it 'returns an unsatisfied ModuleRelease' do
        expect(subject.query('module_name' => '1.0.0')).to_not be_satisfied
      end
    end

    context 'with one source' do
      let(:source) { double('Source') }

      before { Semantic::Dependency.add_source(source) }

      it 'queries the source for release information' do
        source.should_receive(:fetch).with('module_name').and_return([])

        Semantic::Dependency.query('module_name' => '1.0.0')
      end

      it 'queries the source for each dependency' do
        source.should_receive(:fetch).with('module_name').and_return([
          create_release(source, 'module_name', '1.0.0', 'bar' => '1.0.0')
        ])
        source.should_receive(:fetch).with('bar').and_return([])

        Semantic::Dependency.query('module_name' => '1.0.0')
      end

      it 'queries the source for each dependency only once' do
        source.should_receive(:fetch).with('module_name').and_return([
          create_release(
            source,
            'module_name',
            '1.0.0',
            'bar' => '1.0.0', 'baz' => '0.0.2'
          )
        ])
        source.should_receive(:fetch).with('bar').and_return([
          create_release(source, 'bar', '1.0.0', 'baz' => '0.0.3')
        ])
        source.should_receive(:fetch).with('baz').once.and_return([])

        Semantic::Dependency.query('module_name' => '1.0.0')
      end

      it 'returns a ModuleRelease with the requested dependencies' do
        source.stub(:fetch).and_return([])

        result = Semantic::Dependency.query('foo' => '1.0.0', 'bar' => '1.0.0')
        expect(result.dependencies).to match_array %w[ foo bar ]
      end

      it 'populates the returned ModuleRelease with releated dependencies' do
        source.stub(:fetch).and_return(
          [ foo = create_release(source, 'foo', '1.0.0', 'bar' => '1.0.0') ],
          [ bar = create_release(source, 'bar', '1.0.0') ]
        )

        result = Semantic::Dependency.query('foo' => '1.0.0', 'bar' => '1.0.0')
        expect(result.depends_on).to eql 'foo' => [ foo ], 'bar' => [ bar ]
      end

      it 'populates all returned ModuleReleases with releated dependencies' do
        source.stub(:fetch).and_return(
          [ foo = create_release(source, 'foo', '1.0.0', 'bar' => '1.0.0') ],
          [ bar = create_release(source, 'bar', '1.0.0', 'baz' => '0.1.0') ],
          [ baz = create_release(source, 'baz', '0.1.0', 'baz' => '1.0.0') ]
        )

        result = Semantic::Dependency.query('foo' => '1.0.0')
        expect(result.depends_on).to eql 'foo' => [ foo ]
        expect(foo.depends_on).to eql 'bar' => [ bar ]
        expect(bar.depends_on).to eql 'baz' => [ baz ]
      end
    end

    context 'with multiple sources' do
      let(:source1) { double('SourceOne') }
      let(:source2) { double('SourceTwo') }
      let(:source3) { double('SourceThree') }

      before do
        Semantic::Dependency.add_source(source1)
        Semantic::Dependency.add_source(source2)
        Semantic::Dependency.add_source(source3)
      end

      it 'queries each source in turn' do
        source1.should_receive(:fetch).with('module_name').and_return([])
        source2.should_receive(:fetch).with('module_name').and_return([])
        source3.should_receive(:fetch).with('module_name').and_return([])

        Semantic::Dependency.query('module_name' => '1.0.0')
      end

      it 'resolves all dependencies against all sources' do
        source1.should_receive(:fetch).with('module_name').and_return([
          create_release(source1, 'module_name', '1.0.0', 'bar' => '1.0.0')
        ])
        source2.should_receive(:fetch).with('module_name').and_return([])
        source3.should_receive(:fetch).with('module_name').and_return([])

        source1.should_receive(:fetch).with('bar').and_return([])
        source2.should_receive(:fetch).with('bar').and_return([])
        source3.should_receive(:fetch).with('bar').and_return([])

        Semantic::Dependency.query('module_name' => '1.0.0')
      end
    end
  end

  describe '.resolve' do
    def add_source_modules(name, versions, deps = {})
      releases = versions.map { |ver| create_release(source, name, ver, deps) }
      source.stub(:fetch).with(name).and_return(modules[name].concat(releases))
    end

    def subject(specs)
      result = Semantic::Dependency.resolve(Semantic::Dependency.query(specs))
      result.map { |rel| [ rel.name, rel.version.to_s ] }
    end

    let(:modules) { Hash.new { |h,k| h[k] = [] }}
    let(:source) { double('Source') }

    before { Semantic::Dependency.add_source(source) }

    context 'for a module without dependencies' do
      def foo(range)
        subject('foo' => range).map { |x| x.last }
      end

      it 'returns the greatest release matching the version range' do
        add_source_modules('foo', %w[ 0.9.0 1.0.0 1.1.0 2.0.0 ])

        expect(foo('1.x')).to eql %w[ 1.1.0 ]
      end

      context 'when the query includes both stable and prerelease versions' do
        it 'returns the greatest stable release matching the range' do
          add_source_modules('foo', %w[ 0.9.0 1.0.0 1.1.0 1.2.0-pre 2.0.0 ])

          expect(foo('1.x')).to eql %w[ 1.1.0 ]
        end
      end

      context 'when the query omits all stable versions' do
        it 'returns the greatest prerelease version matching the range' do
          add_source_modules('foo', %w[ 1.0.0 1.1.0-a 1.1.0-b 2.0.0 ])

          expect(foo('1.1.x')).to   eql %w[ 1.1.0-b ]
          expect(foo('1.1.0-a')).to eql %w[ 1.1.0-a ]
        end
      end
    end

    context 'for a module with dependencies' do
      def foo(range)
        subject('foo' => range)
      end

      it 'returns the greatest releases matching the dependency range' do
        add_source_modules('foo', %w[ 1.1.0 ], 'bar' => '1.x')
        add_source_modules('bar', %w[ 0.9.0 1.0.0 1.1.0 1.2.0 2.0.0 ])

        expect(foo('1.1.0')).to include %w[ foo 1.1.0 ], %w[ bar 1.2.0 ]
      end

      context 'when the dependency includes both stable and prerelease versions' do
        it 'returns the greatest stable release matching the range' do
          add_source_modules('foo', %w[ 1.1.0 ], 'bar' => '1.x')
          add_source_modules('bar', %w[ 0.9.0 1.0.0 1.1.0 1.2.0-pre 2.0.0 ])

          expect(foo('1.1.0')).to include %w[ foo 1.1.0 ], %w[ bar 1.1.0 ]
        end
      end

      context 'when the dependency omits all stable versions' do
        it 'returns the greatest prerelease version matching the range' do
          add_source_modules('foo', %w[ 1.1.0 ], 'bar' => '1.1.x')
          add_source_modules('foo', %w[ 1.1.1 ], 'bar' => '1.1.0-a')
          add_source_modules('bar', %w[ 1.0.0 1.1.0-a 1.1.0-b 2.0.0 ])

          expect(foo('1.1.0')).to include %w[ foo 1.1.0 ], %w[ bar 1.1.0-b ]
          expect(foo('1.1.1')).to include %w[ foo 1.1.1 ], %w[ bar 1.1.0-a ]
        end
      end
    end

    context 'for a module with competing dependencies' do
      def foo(range)
        subject('foo' => range)
      end

      context 'that overlap' do
        it 'returns the greatest release satisfying all dependencies' do
          add_source_modules('foo', %w[ 1.1.0 ], 'bar' => '1.0.0', 'baz' => '1.0.0')
          add_source_modules('bar', %w[ 1.0.0 ], 'quxx' => '1.x')
          add_source_modules('baz', %w[ 1.0.0 ], 'quxx' => '1.1.x')
          add_source_modules('quxx', %w[ 0.9.0 1.0.0 1.1.0 1.1.1 1.2.0 2.0.0 ])

          expect(foo('1.1.0')).to_not include %w[ quxx 1.2.0 ]
          expect(foo('1.1.0')).to include %w[ quxx 1.1.1 ]
        end
      end

      # context 'when the dependency includes both stable and prerelease versions' do
      #   it 'returns the greatest stable release matching the range' do
      #     add_source_modules('foo', %w[ 1.1.0 ], 'bar' => '1.x')
      #     add_source_modules('bar', %w[ 0.9.0 1.0.0 1.1.0 1.2.0-pre 2.0.0 ])
      # 
      #     expect(foo('1.1.0')).to include %w[ foo 1.1.0 ], %w[ bar 1.1.0 ]
      #   end
      # end
      # 
      # context 'when the dependency omits all stable versions' do
      #   it 'returns the greatest prerelease version matching the range' do
      #     add_source_modules('foo', %w[ 1.1.0 ], 'bar' => '1.1.x')
      #     add_source_modules('foo', %w[ 1.1.1 ], 'bar' => '1.1.0-a')
      #     add_source_modules('bar', %w[ 1.0.0 1.1.0-a 1.1.0-b 2.0.0 ])
      # 
      #     expect(foo('1.1.0')).to include %w[ foo 1.1.0 ], %w[ bar 1.1.0-b ]
      #     expect(foo('1.1.1')).to include %w[ foo 1.1.1 ], %w[ bar 1.1.0-a ]
      #   end
      # end
    end
  end
end
