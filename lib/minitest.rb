require 'rubygems'
gem 'rspec', '>= 1.1.2'
gem 'rcov', '>= 0.8.1.2.0'

class Minitest
  attr_reader :file_mtime
  attr_reader :file_spec
  attr_accessor :rcov_ignores
  attr_accessor :recent
  attr_accessor :recent_time
  attr_accessor :source_dirs
  attr_accessor :source_extensions
  attr_accessor :spec_cmd
  attr_accessor :spec_opts
  
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
    @rcov_ignores || "spec/,db/,/usr/bin/spec,plugins/,vendor/,config/"
  end

  # Command line string to run rcov for all monitored specs.
  def rcov
    "rcov -T --exclude \"#{self.rcov_ignores}\" -Ilib /usr/bin/spec -- " + self.unique_specs.join(" ")
  end

  def recent?
    @recent == true
  end

  # Maximum amount of seconds since a file has been changed for it to count as
  # recently changed.
  def recent_time
    @recent_time || 3600
  end

  # Command line string to run rspec for an array of specs. Defaults to all specs.
  def rspec(specs=self.unique_specs)
    "#{self.spec_cmd} #{specs.join(" ")} #{self.spec_opts}"
  end

  def source_dirs
    @source_dirs || %w[lib app]
  end

  def source_extensions
    @source_extensions || %w[rb haml rhtml erb]
  end

  # The command to use to run specs.
  def spec_cmd
    @spec_cmd ||= ( File.exist?('script/spec') ? 'script/spec' : 'spec' )
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
    if first_run? and recent?
      need_checking.reject! { |file| @file_mtime[file] < ( Time.now - recent_time ) }
      if need_checking.size > 0
        puts "This first run will only test files changed in the last hour. All other files are still monitored."
      else
        puts "No files were changed in the last hour, so no files are tested for the first run."
      end
    end
    @first_run = false
    return need_checking.sort
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
