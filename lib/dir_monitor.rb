# Dirmonitor's purpose is to serve as a file monitoring helper for Minitest.
#
# Its intended functionality is:
# - Keep track of new files in monitored directories.
# - Keep track of changed files in monitored directories.
# - Link these files to their specs or tests, so Minitest can run them.
class DirMonitor
  attr_reader :known_files, :dirs, :last_mtime

  # Setup a new DirMonitor.
  #
  # The input parameter(s) are flattened and forced to a string.
  #
  # This means that directories can be provided in a number of ways:
  #   DirMonitor.new 'lib', 'app'
  #   DirMonitor.new :lib, :app
  #   DirMonitor.new %w[lib app]
  # Each of these examples will result in the same list of directories being stored for use.
  def initialize(*dirs)
    @dirs = dirs.flatten.map{|dir| dir.to_s}
    @known_files = []
    @last_mtime = {}
  end

  # Scan for all files in the directories and their sub-directories.
  # The results are stored as a single array in @known_files.
  def scan
    results = []
    dirs.each do |dir|
      files_in_dir = Dir.glob(File.join(dir,'**','*'))
      results.concat(files_in_dir)
    end
    @known_files = results
  end

  # Scan for changes in the known files.
  # Yields the name of the changed files.
  # Stores the mtime for all changed files.
  def scan_changed(&block) # :yields: file
    known_files.each do |known_file|
      new_mtime = mtime_for(known_file)
      if new_mtime != last_mtime[known_file]
        block.call(known_file)
        last_mtime[known_file]= new_mtime
      end
    end
  end

  # Scan for new files.
  # All new file names are yielded.
  def scan_new(&block) # :yields: file
    old_known_files = @known_files
    scan
    new_files = known_files - old_known_files
    new_files.each do |new_file|
      block.call(new_file)
    end
  end

  # Scan for new files and check for changed known files.
  # The same file is not yielded twice.
  def scan_new_or_changed_with_spec(&block) # :yields: file, spec
    yielded_files = {}
    yield_once_block = Proc.new do |file|
      spec_file = spec_for(file)
      next if yielded_files.has_key? spec_file
      next unless File.exist?(spec_file)
      block.call(file, spec_file)
      yielded_files[spec_file]=file
    end
    scan_new(&yield_once_block)
    scan_changed(&yield_once_block)
  end

  # Scan for new files and check for changed known files.
  # The same file is not yielded twice.
  def scan_new_or_changed_with_test(&block) # :yields: file, test
    yielded_files = {}
    yield_once_block = Proc.new do |file|
      test_file = test_for(file)
      next if yielded_files.has_key? test_file
      next unless File.exist?(test_file)
      block.call(file, test_file)
      yielded_files[test_file]=file
    end
    scan_new(&yield_once_block)
    scan_changed(&yield_once_block)
  end

  # Find the (theoretical) spec file name for a given file.
  # The assumptions are:
  # - All specs reside in the 'spec' directory.
  # - The directory structure is the same; lib/a/b/c maps to spec/a/b/c.
  # - All specs file names have the suffix '_spec.rb'; Ruby code has the '.rb' extension.
  # - The file name for a non-ruby file spec simply has '_spec.rb' suffixed to the entire file name.
  # The returned file name does not necessarily have to exist.
  def spec_for(file)
    base = File.basename(file)
    extension = File.extname(base)
    dir = File.dirname(file)
    dir_array = dir.split('/')
    if extension == '.rb' and dir_array.first=='spec'
      return file
    end
    if extension == '.rb'
      base_without_extension = base[0, base.size - extension.size]
      spec_file = base_without_extension + '_spec' + extension
    else
      spec_file = base + '_spec.rb'
    end
    dir_array[0]='spec'
    spec_dir = dir_array.join('/')
    return File.join(spec_dir, spec_file)
  end

  # Find the (theoretical) test file name for a given file.
  # The assumptions are:
  # - All tests reside in the 'test' directory.
  # - The directory structure is the same; lib/a/b/c maps to test/a/b/c.
  # - Rails is the exception to this rule: 
  #   - Controllers are tested in test/functional
  #   - Models are tested in test/unit
  # - All test file names have the suffix '_test.rb'. Ruby code has the '.rb' extension.
  # - The file name for a non-ruby file test simply has '_test.rb' suffixed to the entire file name.
  # The returned file name does not necessarily have to exist.
  def test_for(file)
    base = File.basename(file)
    extension = File.extname(base)
    dir = File.dirname(file)
    dir_array = dir.split('/')
    if extension == '.rb' and dir_array.first=='test'
      return file
    end
    if extension == '.rb'
      base_without_extension = base[0, base.size - extension.size]
      test_file = base_without_extension + '_test' + extension
    else
      test_file = base + '_test.rb'
    end
    dir_array[0]='test'
    case dir_array[1]
    when 'controllers'
      dir_array[1] = 'functional'
    when 'models'
      dir_array[1] = 'unit'
    end
    test_dir = dir_array.join('/')
    return File.join(test_dir, test_file)
  end

private

  # Get the modification time for a file.
  def mtime_for(file)
    File.mtime(file)
  end
end