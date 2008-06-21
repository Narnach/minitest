require 'rubygems'
gem 'rspec', '>= 1.1.2'
gem 'rcov', '>= 0.8.1.2.0'

# = Minitest
# The default usage of Minitest is this:
#   minitest = Minitest.new
#   minitest.start
# This will do the following:
# - Lookup all spec files in the spec/ directory.
# - Lookup all possible associated files in the lib/ and app/ directories.
# - Remember the mtimes (last modification times) of all relevant files.
# - Every second, check all known relevant files: if their mtime changes, run rspec on their spec file.
# - Run rcov (code coverage tester) on all specs when exiting (Press ctrl-C on send SIGINT to the process)
class Minitest
  VERSION = '0.1.3'
  attr_reader :file_mtime
  attr_reader :file_spec
  attr_accessor :rcov_ignores
  attr_accessor :recent
  attr_accessor :recent_time
  attr_accessor :source_dirs
  attr_accessor :source_extensions
  attr_accessor :spec_cmd
  attr_accessor :spec_opts
  
  DEFAULT_RCOV_IGNORES = %w[spec/ db/ plugins/ vendor/ config/]
  DEFAULT_RECENT_TIME = 3600
  DEFAULT_SOURCE_DIRS = %w[lib app]
  DEFAULT_SOURCE_EXTENSIONS = %w[rb haml rhtml erb]
  
  def initialize
    @file_spec  = {}   # Map files to their specs
    @file_mtime = {}   # Map files to their mtimes
    @need_testing = [] # Specs that need testing
    @first_run = true
    @active = false
  end

  def active?
    @active == true
  end

  def first_run?
    @first_run == true
  end

  # Partial filepaths to exclude from rcov output
  def rcov_ignores
    ignores = @rcov_ignores || DEFAULT_RCOV_IGNORES
    ignores << spec_cmd
    ignores.join(",")
  end

  # Command line string to run rcov for all monitored specs.
  def rcov
    "#{rcov_cmd} -T --exclude \"#{rcov_ignores}\" -Ilib #{spec_cmd} -- " + self.unique_specs.join(" ")
  end

  def recent?
    @recent == true
  end

  # Maximum amount of seconds since a file has been changed for it to count as
  # recently changed.
  def recent_time
    @recent_time || DEFAULT_RECENT_TIME
  end

  # Command line string to run rspec for an array of specs. Defaults to all specs.
  def rspec(specs=self.unique_specs)
    "#{spec_cmd} #{specs.join(" ")} #{spec_opts}"
  end

  def source_dirs
    @source_dirs || DEFAULT_SOURCE_DIRS
  end

  def source_extensions
    @source_extensions || DEFAULT_SOURCE_EXTENSIONS
  end
  
  def rcov_cmd
    @rcov_cmd ||= find_rcov_cmd
  end

  # The command to use to run specs.
  def spec_cmd
    @spec_cmd ||= ( File.exist?('script/spec') ? 'script/spec' : find_spec_cmd )
  end

  def spec_opts
    @spec_opts ||= ( File.exist?('spec/spec.opts') ? '-O spec/spec.opts' : '' )
  end

  def start
    @active = true
    find_specs
    
    if self.file_spec.values.uniq.size == 0
      puts "There are no specs to run."
      return
    end
    
    need_testing = find_first_run_specs
    
    trap_int_for_rcov
    while active? do
      if need_testing.size > 0
        print "\nTesting files: #{need_testing.join(" ")}\n"
        system rspec(need_testing)
      end
      sleep 1
      need_testing = find_specs_to_check
    end
  end

  def trap_int_for_rcov
    Signal.trap("INT") do
      print "\nNow we run rcov and we're done.\n\n"
      puts rcov
      system rcov
      @active = false
    end
  end

  def unique_specs
    self.file_spec.values.uniq.sort
  end

private

  def find_first_run_specs
    need_checking = self.file_mtime.keys.dup
    specs_to_check = []
    if first_run? and recent?
      need_checking.reject! { |file| @file_mtime[file] < ( Time.now - recent_time ) }
      if need_checking.size > 0
        puts "This first run will only test files changed in the last hour. All other files are still monitored."
      else
        puts "No files were changed in the last hour, so no files are tested for the first run."
      end
    end
    specs_to_check = need_checking.map {|f| @file_spec[f]}
    specs_to_check.uniq!
    specs_to_check.sort!
    @first_run = false
    return specs_to_check
  end
  
  def find_sources_for_spec(spec)
    found_files = []
    for dir in self.source_dirs
      next unless spec[0,4]=='spec'
      
      file = spec.dup
      file[0,4]=dir
      file.gsub!("_spec.",".")
      candidates = self.source_extensions.map { |ext| file.gsub(/[^.]+\Z/, ext)}
      candidates = candidates.select { |f| File.exist?(f) }
      found_files += candidates
    end
    found_files.uniq!
    return found_files
  end
  
  def find_rcov_cmd
    `which rcov`.strip
  end
  
  def find_spec_cmd
    `which spec`.strip
  end

  def find_specs
    Dir.glob("spec/**/*_spec.rb").each do |spec|
      # If a spec changes, run it again.
      map_file_to_spec(spec,spec)
      for file in find_sources_for_spec(spec)
        map_file_to_spec(file,spec)
      end
    end
  end

  def find_specs_to_check
    specs = []
    @file_mtime.each do |file, old_mtime|
      current_mtime = File.mtime(file)
      if current_mtime != old_mtime
        specs << @file_spec[file]
        store_mtime file
      end
    end
    specs.uniq!
    specs.sort!
    return specs
  end
  
  def map_file_to_spec(file,spec)
    return if @file_mtime.has_key? file
    @file_spec[file.dup]=spec.dup
    store_mtime file
    store_mtime spec
  end

  def store_mtime(file)
    @file_mtime[file.dup] = File.mtime(file)
  end
end
