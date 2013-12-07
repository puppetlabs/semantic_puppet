require 'spec_helper'
require 'semantic/version'

describe Semantic::Version do

  describe '.parse' do

    def subject(str)
      Semantic::Version.parse(str)
    end

    context 'Spec v2.0.0' do

      context 'Section 2' do
        # A normal version number MUST take the form X.Y.Z where X, Y, and Z are
        # non-negative integers, and MUST NOT contain leading zeroes. X is the
        # major version, Y is the minor version, and Z is the patch version.
        # Each element MUST increase numerically.
        # For instance: 1.9.0 -> 1.10.0 -> 1.11.0.

        let(:must_begin_with_digits) do
          'Version numbers MUST begin with X.Y.Z'
        end

        let(:no_leading_zeroes) do
          'Version numbers MUST NOT contain leading zeroes'
        end

        it 'rejects versions that contain too few parts' do
          expect { subject('1.2') }.to raise_error(must_begin_with_digits)
        end

        it 'rejects versions that contain too many parts' do
          expect { subject('1.2.3.4') }.to raise_error(must_begin_with_digits)
        end

        it 'rejects versions that contain non-integers' do
          expect { subject('x.2.3') }.to raise_error(must_begin_with_digits)
          expect { subject('1.y.3') }.to raise_error(must_begin_with_digits)
          expect { subject('1.2.z') }.to raise_error(must_begin_with_digits)
        end

        it 'rejects versions that contain negative integers' do
          expect { subject('-1.2.3') }.to raise_error(must_begin_with_digits)
          expect { subject('1.-2.3') }.to raise_error(must_begin_with_digits)
          expect { subject('1.2.-3') }.to raise_error(must_begin_with_digits)
        end

        it 'rejects version numbers containing leading zeroes' do
          expect { subject('01.2.3') }.to raise_error(no_leading_zeroes)
          expect { subject('1.02.3') }.to raise_error(no_leading_zeroes)
          expect { subject('1.2.03') }.to raise_error(no_leading_zeroes)
        end

        it 'permits zeroes in version number parts' do
          expect { subject('0.2.3') }.to_not raise_error
          expect { subject('1.0.3') }.to_not raise_error
          expect { subject('1.2.0') }.to_not raise_error
        end

        context 'examples' do
          example '1.9.0' do
            version = subject('1.9.0')
            expect(version.major).to eql 1
            expect(version.minor).to eql 9
            expect(version.patch).to eql 0
          end

          example '1.10.0' do
            version = subject('1.10.0')
            expect(version.major).to eql 1
            expect(version.minor).to eql 10
            expect(version.patch).to eql 0
          end

          example '1.11.0' do
            version = subject('1.11.0')
            expect(version.major).to eql 1
            expect(version.minor).to eql 11
            expect(version.patch).to eql 0
          end
        end
      end

      context 'Section 9' do
        # A pre-release version MAY be denoted by appending a hyphen and a
        # series of dot separated identifiers immediately following the patch
        # version. Identifiers MUST comprise only ASCII alphanumerics and
        # hyphen [0-9A-Za-z-]. Identifiers MUST NOT be empty. Numeric
        # identifiers MUST NOT include leading zeroes. Pre-release versions
        # have a lower precedence than the associated normal version. A
        # pre-release version indicates that the version is unstable and
        # might not satisfy the intended compatibility requirements as denoted
        # by its associated normal version.
        # Examples: 1.0.0-alpha, 1.0.0-alpha.1, 1.0.0-0.3.7, 1.0.0-x.7.z.92.

        let(:restricted_charset) do
          'Prerelease identifiers MUST use only ASCII alphanumerics and hyphens'
        end

        let(:must_not_be_empty) do
          'Prerelease identifiers MUST NOT be empty'
        end

        let(:no_leading_zeroes) do
          'Prerelease identifiers MUST NOT contain leading zeroes'
        end

        it 'rejects prerelease identifiers with non-alphanumerics' do
          expect { subject('1.2.3-$100') }.to raise_error(restricted_charset)
          expect { subject('1.2.3-rc.1@me') }.to raise_error(restricted_charset)
        end

        it 'rejects empty prerelease versions' do
          expect { subject('1.2.3-') }.to raise_error(must_not_be_empty)
        end

        it 'rejects empty prerelease version identifiers' do
          expect { subject('1.2.3-.rc1') }.to raise_error(must_not_be_empty)
          expect { subject('1.2.3-rc1.') }.to raise_error(must_not_be_empty)
          expect { subject('1.2.3-rc..1') }.to raise_error(must_not_be_empty)
        end

        it 'rejects numeric prerelease identifiers with leading zeroes' do
          expect { subject('1.2.3-01') }.to raise_error(no_leading_zeroes)
          expect { subject('1.2.3-rc.01') }.to raise_error(no_leading_zeroes)
        end

        it 'permits numeric prerelease identifiers of zero' do
          expect { subject('1.2.3-0') }.to_not raise_error
          expect { subject('1.2.3-rc.0') }.to_not raise_error
        end

        it 'permits non-numeric prerelease identifiers with leading zeroes' do
          expect { subject('1.2.3-0xDEADBEEF') }.to_not raise_error
          expect { subject('1.2.3-rc.0x10c') }.to_not raise_error
        end

        context 'examples' do
          example '1.0.0-alpha' do
            version = subject('1.0.0-alpha')
            expect(version.major).to eql 1
            expect(version.minor).to eql 0
            expect(version.patch).to eql 0
            expect(version.prerelease).to eql 'alpha'
          end

          example '1.0.0-alpha.1' do
            version = subject('1.0.0-alpha.1')
            expect(version.major).to eql 1
            expect(version.minor).to eql 0
            expect(version.patch).to eql 0
            expect(version.prerelease).to eql 'alpha.1'
          end

          example '1.0.0-0.3.7' do
            version = subject('1.0.0-0.3.7')
            expect(version.major).to eql 1
            expect(version.minor).to eql 0
            expect(version.patch).to eql 0
            expect(version.prerelease).to eql '0.3.7'
          end

          example '1.0.0-x.7.z.92' do
            version = subject('1.0.0-x.7.z.92')
            expect(version.major).to eql 1
            expect(version.minor).to eql 0
            expect(version.patch).to eql 0
            expect(version.prerelease).to eql 'x.7.z.92'
          end
        end
      end

      context 'Section 10' do
        # Build metadata MAY be denoted by appending a plus sign and a series
        # of dot separated identifiers immediately following the patch or
        # pre-release version. Identifiers MUST comprise only ASCII
        # alphanumerics and hyphen [0-9A-Za-z-]. Identifiers MUST NOT be empty.
        # Build metadata SHOULD be ignored when determining version precedence.
        # Thus two versions that differ only in the build metadata, have the
        # same precedence.
        # Examples: 1.0.0-alpha+001, 1.0.0+20130313144700,
        # 1.0.0-beta+exp.sha.5114f85.


        let(:restricted_charset) do
          'Build identifiers MUST use only ASCII alphanumerics and hyphens'
        end

        let(:must_not_be_empty) do
          'Build identifiers MUST NOT be empty'
        end

        it 'rejects build identifiers with non-alphanumerics' do
          expect { subject('1.2.3+$100') }.to raise_error(restricted_charset)
          expect { subject('1.2.3+rc.1@me') }.to raise_error(restricted_charset)
        end

        it 'rejects empty build metadata' do
          expect { subject('1.2.3+') }.to raise_error(must_not_be_empty)
        end

        it 'rejects empty build identifiers' do
          expect { subject('1.2.3+.rc1') }.to raise_error(must_not_be_empty)
          expect { subject('1.2.3+rc1.') }.to raise_error(must_not_be_empty)
          expect { subject('1.2.3+rc..1') }.to raise_error(must_not_be_empty)
        end

        it 'permits numeric build identifiers with leading zeroes' do
          expect { subject('1.2.3+01') }.to_not raise_error
          expect { subject('1.2.3+rc.01') }.to_not raise_error
        end

        it 'permits numeric build identifiers of zero' do
          expect { subject('1.2.3+0') }.to_not raise_error
          expect { subject('1.2.3+rc.0') }.to_not raise_error
        end

        it 'permits non-numeric build identifiers with leading zeroes' do
          expect { subject('1.2.3+0xDEADBEEF') }.to_not raise_error
          expect { subject('1.2.3+rc.0x10c') }.to_not raise_error
        end

        context 'examples' do
          example '1.0.0-alpha+001' do
            version = subject('1.0.0-alpha+001')
            expect(version.major).to eql 1
            expect(version.minor).to eql 0
            expect(version.patch).to eql 0
            expect(version.prerelease).to eql 'alpha'
            expect(version.build).to eql '001'
          end

          example '1.0.0+20130313144700' do
            version = subject('1.0.0+20130313144700')
            expect(version.major).to eql 1
            expect(version.minor).to eql 0
            expect(version.patch).to eql 0
            expect(version.prerelease).to eql nil
            expect(version.build).to eql '20130313144700'
          end

          example '1.0.0-beta+exp.sha.5114f85' do
            version = subject('1.0.0-beta+exp.sha.5114f85')
            expect(version.major).to eql 1
            expect(version.minor).to eql 0
            expect(version.patch).to eql 0
            expect(version.prerelease).to eql 'beta'
            expect(version.build).to eql 'exp.sha.5114f85'
          end
        end
      end

    end

  end

end