# Dirmonitor's purpose is to serve as a file monitoring helper for Minitest.
# Its intended functionality is:
# - Keep track of new files in monitored directories.
# - Keep track of changed files in monitored directories.
# - Link these files to their specs, so Minitest can run the specs.
class DirMonitor
  attr_reader :known_files, :dirs
  
  # Setup a new DirMonitor.
  # Directories can be provided in a number of ways:
  #   DirMonitor.new 'lib', 'app'
  #   DirMonitor.new :lib, :app
  #   DirMonitor.new %w[lib app]
  # Each of these examples will result in the same list of directories being stored for use.
  def initialize(*dirs)
    @dirs = dirs.flatten.map{|dir| dir.to_s}
    @known_files = []
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
  
  # Scans for new files, like scan_new does, but yields the name of both the file and spec.
  # spec_for is used to determine what the name of the file's spec _should_ be.
  # Does not yield a file/spec name when the spec does not exist.
  def scan_new_with_spec(&block) # :yields: file, spec
    scan_new do |file|
      spec = spec_for(file)
      block.call(file, spec) if File.exists?(spec)
    end
  end
  
  # Find the (theoretical) spec file name for a given file.
  # The assumptions are:
  # - All specs reside in the 'spec' directory.
  # - All specs file names have the suffix '_spec.rb', instead of only the '.rb' extension.
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
end