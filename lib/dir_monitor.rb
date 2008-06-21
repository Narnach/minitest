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
end