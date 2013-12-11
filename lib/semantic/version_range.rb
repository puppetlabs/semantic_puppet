require 'semantic'

module Semantic
  class VersionRange < Range
    class << self
      # @todo Actually parse the set of version ranges described here https://github.com/mojombo/semver/issues/113#issuecomment-19347872
      # @todo Ensure that set of version ranges overlaps with https://github.com/puppetlabs/puppet/blob/master/lib/semver.rb#L24
      def parse(range)
        pre = proc do |v|
          v.instance_eval do
            @prerelease = []
            self
          end
        end

        if range == '>= 0.0.0'
          self.new Version.new(0, 0, 0, []), Version.new((1.0/0.0), 0, 0)
        elsif range =~ /\A(\d+)(?:[.][xX*])?(?:[.][xX*])?\Z/
          self.new pre[Version.parse("#{$1}.0.0")], Version.parse("#{$1.to_i + 1}.0.0"), true
        elsif range =~ /\A(\d+)[.](\d+)(?:[.][xX*])?\Z/
          self.new pre[Version.parse("#{$1}.#{$2}.0")], Version.parse("#{$1}.#{$2.to_i + 1}.0"), true
        else
          self.new pre[Version.parse(range)], Version.parse(range)
        end
      end
    end
  end
end
