Gem::Specification.new do |s|
  # Project
  s.name         = 'minitest'
  s.summary      = "Minitest is a simple autotester tool."
  s.description  = "Minitest is a simple autotester tool, which uses rSpec and rCov to test ruby and rails projects."
  s.version      = '0.3.1'
  s.date         = '2008-08-14'
  s.platform     = Gem::Platform::RUBY
  s.authors      = ["Wes Oldenbeuving"]
  s.email        = "narnach@gmail.com"
  s.homepage     = "http://www.github.com/Narnach/minitest"

  # Files
  root_files     = %w[MIT-LICENSE README.rdoc Rakefile minitest.gemspec]
  bin_files      = %w[minitest]
  lib_files      = %w[minitest dir_monitor]
  test_files     = %w[]
  spec_files     = %w[dir_monitor minitest]
  s.bindir       = "bin"
  s.require_path = "lib"
  s.executables  = bin_files
  s.test_files   = test_files.map {|f| 'test/%s_test.rb' % f} + spec_files.map {|f| 'spec/%s_spec.rb' % f}
  s.files        = root_files + s.test_files + bin_files.map {|f| 'bin/%s' % f} + lib_files.map {|f| 'lib/%s.rb' % f}

  # rdoc
  s.has_rdoc         = true
  s.extra_rdoc_files = %w[ README.rdoc MIT-LICENSE]
  s.rdoc_options << '--inline-source' << '--line-numbers' << '--main' << 'README.rdoc'

  # Dependencies
  s.add_dependency 'rspec', "> 0.0.0"
  s.add_dependency 'rcov',  "> 0.0.0"

  # Requirements
  s.required_ruby_version = ">= 1.8.0"
end
