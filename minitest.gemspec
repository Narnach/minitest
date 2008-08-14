Gem::Specification.new do |s|
  # Project
  s.name         = 'minitest'
  s.summary      = "Minitest is a simple autotester tool."
  s.description  = "Minitest is a simple autotester tool, which uses rSpec and rCov to test ruby and rails projects."
  s.version      = '0.3.0'
  s.date         = '2008-08-14'
  s.platform     = Gem::Platform::RUBY
  s.authors      = ["Wes Oldenbeuving"]
  s.email        = "narnach@gmail.com"
  s.homepage     = "http://www.github.com/Narnach/minitest"

  # Files
  s.bindir       = "bin"
  s.executables  = %w[minitest]
  s.require_path = "lib"
  s.files        = ['MIT-LICENSE', 'README.rdoc', 'Rakefile', 'bin/minitest', 'lib/dir_monitor.rb', 'lib/minitest.rb', 'spec/dir_monitor_spec.rb', 'spec/minitest_spec.rb', 'spec/spec.opts']
  s.test_files   = ['spec/dir_monitor_spec.rb', 'spec/minitest_spec.rb', 'spec/spec.opts']

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
