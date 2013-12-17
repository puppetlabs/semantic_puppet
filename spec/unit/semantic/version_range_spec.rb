require 'spec_helper'
require 'semantic/version'

describe Semantic::VersionRange do

  describe '.parse' do
    def self.test_range(range_list, includes, excludes)
      Array(range_list).each do |expr|
        range = Semantic::VersionRange.parse(expr)

        includes.each do |vstring|
          example "#{expr.inspect} includes #{vstring}" do
            expect(range).to include(Semantic::Version.parse(vstring))
          end
        end

        excludes.each do |vstring|
          example "#{expr.inspect} excludes #{vstring}" do
            expect(range).to_not include(Semantic::Version.parse(vstring))
          end
        end
      end
    end

    context 'single version expressions' do
      expressions = {
        '1.2.3' => {
          :includes => [ '1.2.3-alpha', '1.2.3' ],
          :excludes => [ '1.2.2', '1.2.4-alpha' ],
        },
        '1.2.3-alpha' => {
          :includes => [ '1.2.3-alpha'  ],
          :excludes => [ '1.2.3-999', '1.2.3-beta' ],
        },
      }

      expressions.each do |range, vs|
        test_range(range, vs[:includes], vs[:excludes])
      end
    end

    context 'major.minor expressions' do
      expressions = {
        [ '1.2', '1.2.x', '1.2.X', '1.2.*' ] => {
          :includes => [ '1.2.0-alpha', '1.2.0', '1.2.999' ],
          :excludes => [ '1.1.999', '1.3.0-0' ],
        },
      }

      expressions.each do |range, vs|
        test_range(range, vs[:includes], vs[:excludes])
      end
    end

    context 'major-only expressions' do
      expressions = {
        [ '1', '1.x', '1.X', '1.*' ] => {
          :includes => [ '1.0.0-alpha', '1.999.0' ],
          :excludes => [ '0.999.999', '2.0.0-0' ],
        },
      }

      expressions.each do |range, vs|
        test_range(range, vs[:includes], vs[:excludes])
      end
    end

    context 'open-ended expressions' do
      expressions = {
        [ '>1', '> 1' ] => {
          :includes => [ '2.0.0-0', '999.0.0' ],
          :excludes => [ '1.999.999' ],
        },
        [ '>1.2', '> 1.2' ] => {
          :includes => [ '1.3.0-0', '999.0.0' ],
          :excludes => [ '1.2.999' ],
        },
        [ '>1.2.3', '> 1.2.3' ] => {
          :includes => [ '1.2.4-0', '999.0.0' ],
          :excludes => [ '1.2.3' ],
        },
        [ '>1.2.3-alpha', '> 1.2.3-alpha' ] => {
          :includes => [ '1.2.3-alpha.0', '1.2.3-alpha0', '999.0.0' ],
          :excludes => [ '1.2.3-alpha' ],
        },

        [ '>=1', '>= 1' ] => {
          :includes => [ '1.0.0-0', '999.0.0' ],
          :excludes => [ '0.999.999' ],
        },
        [ '>=1.2', '>= 1.2' ] => {
          :includes => [ '1.2.0-0', '999.0.0' ],
          :excludes => [ '1.1.999' ],
        },
        [ '>=1.2.3', '>= 1.2.3' ] => {
          :includes => [ '1.2.3-0', '999.0.0' ],
          :excludes => [ '1.2.2' ],
        },
        [ '>=1.2.3-alpha', '>= 1.2.3-alpha' ] => {
          :includes => [ '1.2.3-alpha', '1.2.3-alpha0', '999.0.0' ],
          :excludes => [ '1.2.3-alph' ],
        },

        [ '<1', '< 1' ] => {
          :includes => [ '0.0.0-0', '0.999.999' ],
          :excludes => [ '1.0.0-0', '2.0.0' ],
        },
        [ '<1.2', '< 1.2' ] => {
          :includes => [ '0.0.0-0', '1.1.0' ],
          :excludes => [ '1.2.0-0', '2.0.0' ],
        },
        [ '<1.2.3', '< 1.2.3' ] => {
          :includes => [ '0.0.0-0', '1.2.2' ],
          :excludes => [ '1.2.3-0', '2.0.0' ],
        },
        [ '<1.2.3-alpha', '< 1.2.3-alpha' ] => {
          :includes => [ '0.0.0-0', '1.2.3-alph' ],
          :excludes => [ '1.2.3-alpha', '2.0.0' ],
        },

        [ '<=1', '<= 1' ] => {
          :includes => [ '0.0.0-0', '1.999.999' ],
          :excludes => [ '2.0.0-0' ],
        },
        [ '<=1.2', '<= 1.2' ] => {
          :includes => [ '0.0.0-0', '1.2.999' ],
          :excludes => [ '1.3.0-0' ],
        },
        [ '<=1.2.3', '<= 1.2.3' ] => {
          :includes => [ '0.0.0-0', '1.2.3' ],
          :excludes => [ '1.2.4-0' ],
        },
        [ '<=1.2.3-alpha', '<= 1.2.3-alpha' ] => {
          :includes => [ '0.0.0-0', '1.2.3-alpha' ],
          :excludes => [ '1.2.3-alpha0', '1.2.3-alpha.0' ],
        },
      }

      expressions.each do |range, vs|
        test_range(range, vs[:includes], vs[:excludes])
      end
    end

    context '"reasonably close" expressions' do
      expressions = {
        '~1' => {
          :includes => [ '1.0.0-0', '1.999.999' ],
          :excludes => [ '0.999.999', '2.0.0-0' ],
        },
        '~1.2' => {
          :includes => [ '1.2.0-0', '1.2.999' ],
          :excludes => [ '1.1.999', '1.3.0-0' ],
        },
        '~1.2.3' => {
          :includes => [ '1.2.3-0', '1.2.3' ],
          :excludes => [ '1.2.2', '1.2.4-0' ],
        },
        '~1.2.3-alpha' => {
          :includes => [ '1.2.3-alpha', '1.2.3' ],
          :excludes => [ '1.2.3-alph', '1.2.4-0' ],
        },
      }

      expressions.each do |range, vs|
        test_range(range, vs[:includes], vs[:excludes])
      end
    end

    context 'inclusive range expressions' do
      expressions = {
        '1 - 2' => {
          :includes => [ '1.0.0-0', '2.999.999' ],
          :excludes => [ '0.999.999', '3.0.0-0' ],
        },
        '1 - 2.4' => {
          :includes => [ '1.0.0-0', '2.4.999' ],
          :excludes => [ '0.999.999', '2.5.0-0' ],
        },
        '1 - 2.3.4' => {
          :includes => [ '1.0.0-0', '2.3.4' ],
          :excludes => [ '0.999.999', '2.3.5-0' ],
        },
        '1 - 2.3.4-alpha' => {
          :includes => [ '1.0.0-0', '2.3.4-alpha' ],
          :excludes => [ '0.999.999', '2.3.4-alpha0', '2.3.4' ],
        },

        '1.2 - 2' => {
          :includes => [ '1.2.0-0', '2.999.999' ],
          :excludes => [ '1.1.999', '3.0.0-0' ],
        },
        '1.2 - 1.4' => {
          :includes => [ '1.2.0-0', '1.4.999' ],
          :excludes => [ '1.1.999', '1.5.0-0' ],
        },
        '1.2 - 1.2.3' => {
          :includes => [ '1.2.0-0', '1.2.3' ],
          :excludes => [ '1.1.999', '1.2.4-0' ],
        },
        '1.2 - 1.2.3-alpha' => {
          :includes => [ '1.2.0-0' , '1.2.3-alpha' ],
          :excludes => [ '1.1.999', '1.2.3-alpha0', '1.2.4' ],
        },

        '1.2.3 - 2' => {
          :includes => [ '1.2.3-0', '2.999.999' ],
          :excludes => [ '1.2.2', '3.0.0-0' ],
        },
        '1.2.3 - 1.4' => {
          :includes => [ '1.2.3-0', '1.4.999' ],
          :excludes => [ '1.2.2', '1.5.0-0' ],
        },
        '1.2.3 - 1.3.4' => {
          :includes => [ '1.2.3-0', '1.3.4' ],
          :excludes => [ '1.2.2', '1.3.5-0' ],
        },
        '1.2.3 - 1.3.4-alpha' => {
          :includes => [ '1.2.3-0', '1.3.4-alpha' ],
          :excludes => [ '1.2.2', '1.3.4-alpha0', '1.3.5' ],
        },

        '1.2.3-alpha - 2' => {
          :includes => [ '1.2.3-alpha', '2.999.999' ],
          :excludes => [ '1.2.3-alph', '3.0.0-0' ],
        },
        '1.2.3-alpha - 1.4' => {
          :includes => [ '1.2.3-alpha', '1.4.999' ],
          :excludes => [ '1.2.3-alph', '1.5.0-0' ],
        },
        '1.2.3-alpha - 1.3.4' => {
          :includes => [ '1.2.3-alpha', '1.3.4' ],
          :excludes => [ '1.2.3-alph', '1.3.5-0' ],
        },
        '1.2.3-alpha - 1.3.4-alpha' => {
          :includes => [ '1.2.3-alpha', '1.3.4-alpha' ],
          :excludes => [ '1.2.3-alph', '1.3.4-alpha0', '1.3.5' ],
        },
      }

      expressions.each do |range, vs|
        test_range(range, vs[:includes], vs[:excludes])
      end
    end
  end
end
