require "rake"
require "rake/clean"
require "rake/gempackagetask"
require 'rubygems'
require 'lib/minitest'

################################################################################
### Gem
################################################################################

spec = Gem::Specification.new do |s|
  s.name         = 'minitest'
  s.version      = Minitest::VERSION
  s.platform     = Gem::Platform::RUBY
  s.author       = "Wes Oldenbeuving"
  s.email        = "narnach@gmail.com"
  s.homepage     = "http://www.github.com/Narnach/minitest"
  s.summary      = "A simple autotester tool."
  s.bindir       = "bin"
  s.description  = s.summary
  s.executables  = %w[minitest]
  s.require_path = "lib"
  s.files        = Dir["*.rdoc"] + %w( Rakefile MIT-LICENSE ) + Dir["{spec,lib,bin}/**/*"]

  # rdoc
  s.has_rdoc         = true
  s.extra_rdoc_files = Dir["*.rdoc"] + %w( MIT-LICENSE )
  s.rdoc_options << '--inline-source' << '--line-numbers' << '--main' << 'README.rdoc'

  # Dependencies
  s.add_dependency 'rspec', "> 0.0.0"
  s.add_dependency 'rcov',  "> 0.0.0"

  # Requirements
  s.required_ruby_version = ">= 1.8.0"
end

Rake::GemPackageTask.new(spec) do |package|
  package.gem_spec = spec
end

desc 'Package and install the gem for the current version'
task :install => :gem do
  system "sudo gem install -l pkg/minitest-%s.gem" % Minitest::VERSION
end