require 'spec_helper'
require 'semantic/dependency/module_release'

describe Semantic::Dependency::ModuleRelease do
  def make_release(name, version, deps = {})
    Semantic::Dependency::Source::ROOT_CAUSE.create_release(name, version, deps)
  end

  let(:no_dependencies) do
    make_release('module', '1.2.3')
  end

  let(:one_dependency) do
    make_release('module', '1.2.3', 'foo' => '1.0.0')
  end

  let(:three_dependencies) do
    dependencies = { 'foo' => '1.0.0', 'bar' => '2.0.0', 'baz' => '3.0.0' }
    make_release('module', '1.2.3', dependencies)
  end

  describe '#dependencies' do

    it "lists the names of all the release's dependencies" do
      expect(no_dependencies.dependencies).to    match_array %w[ ]
      expect(one_dependency.dependencies).to     match_array %w[ foo ]
      expect(three_dependencies.dependencies).to match_array %w[ foo bar baz ]
    end

  end

  describe '#satisfy_dependencies' do

    it 'marks matching dependencies as satisfied' do
      one_dependency.satisfy_dependencies make_release('foo', '1.0.0')
      expect(one_dependency).to be_satisfied
    end

    it 'does not mark mis-matching dependency names as satisfied' do
      one_dependency.satisfy_dependencies make_release('WAT', '1.0.0')
      expect(one_dependency).to_not be_satisfied
    end

    it 'does not mark mis-matching dependency versions as satisfied' do
      one_dependency.satisfy_dependencies make_release('foo', '0.0.1')
      expect(one_dependency).to_not be_satisfied
    end

  end

  describe '#satisfied?' do

    it 'returns true when there are no dependencies to satisfy' do
      expect(no_dependencies).to be_satisfied
    end

    it 'returns false when no dependencies have been satisified' do
      expect(one_dependency).to_not be_satisfied
    end

    it 'returns false when not all dependencies have been satisified' do
      releases = %w[ 0.9.0 1.0.0 1.0.1 ].map { |ver| make_release('foo', ver) }
      three_dependencies.satisfy_dependencies releases

      expect(three_dependencies).to_not be_satisfied
    end

    it 'returns false when not all dependency versions have been satisified' do
      releases = %w[ 0.9.0 1.0.1 ].map { |ver| make_release('foo', ver) }
      one_dependency.satisfy_dependencies releases

      expect(one_dependency).to_not be_satisfied
    end

    it 'returns true when all dependencies have been satisified' do
      releases = %w[ 0.9.0 1.0.0 1.0.1 ].map { |ver| make_release('foo', ver) }
      one_dependency.satisfy_dependencies releases

      expect(one_dependency).to be_satisfied
    end

  end
end
