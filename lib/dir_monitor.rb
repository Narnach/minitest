class DirMonitor
  attr_reader :known, :dirs
  
  # Setup a new DirMonitor.
  # Directories can be provided in a number of ways:
  #   DirMonitor.new 'lib', 'app'
  #   DirMonitor.new :lib, :app
  #   DirMonitor.new %w[lib app]
  # Each of these examples will result in the same list of directories being stored for use.
  def initialize(*dirs)
    @dirs = dirs.flatten.map{|dir| dir.to_s}
    @known = []
  end
  
  # Scan for all files in the directories and their sub-directories.
  # The results are stored as a single array in known.
  def scan
    @known = dirs.map {|dir| Dir.glob(File.join(dir,'**','*'))}.flatten
  end
  
  # Scan for new files.
  # All new file names are yielded.
  def scan_new(&block)
    old_known = @known
    scan
    (known - old_known).each do |new_file|
      block.call(new_file)
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
    if extension == '.rb' and dir.split('/').first=='spec'
      return file
    end
    if extension == '.rb'
      base_without_extension = base[0, base.size - extension.size]
      spec_file = base_without_extension + '_spec' + extension
    else
      spec_file = base + '_spec.rb'
    end
    spec_dir = dir.gsub(/\A[^\/]*/,'spec')
    return File.join(spec_dir, spec_file)
  end
end