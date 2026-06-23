source "https://rubygems.org"

gemspec

group(:development, optional: true) do
  gem 'rake'
  gem 'rspec'

  unless RUBY_PLATFORM =~ /java/
    gem 'simplecov'
    gem 'cane'
    gem 'yard', '>= 0.9.44'
    gem 'redcarpet'
  end
end
