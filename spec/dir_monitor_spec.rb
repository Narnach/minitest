$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__),'..','lib'))
require 'dir_monitor'

describe DirMonitor, ".new" do
  it "should accept multiple directories" do
    dm = DirMonitor.new('lib','app')
    dm.dirs.should == ['lib','app']
  end

  it "should accept an array with multiple directories" do
    dm = DirMonitor.new(%w[lib app])
    dm.dirs.should == ['lib','app']
  end
  
  it "should have no known files" do
    dm = DirMonitor.new('lib')
    dm.known_files.should == []
  end
end

describe DirMonitor, "#scan" do
  it "should find all files in the directories" do
    known_files1 = %w[lib/minitest.rb lib/dir_monitor.rb]
    known_files2 = %w[app/another.rb app/files.rb app/more/things.txt]
    Dir.should_receive(:glob).with('lib/**/*').and_return(known_files1)
    Dir.should_receive(:glob).with('app/**/*').and_return(known_files2)
    dm = DirMonitor.new('lib', 'app')
    dm.scan
    dm.known_files.should == known_files1 + known_files2
  end
end

describe DirMonitor, "#scan_new" do
  it "should yield the names of all new files" do
    known_files = %w[lib/minitest.rb lib/dir_monitor.rb]
    Dir.should_receive(:glob).with('lib/**/*').and_return(known_files)
    dm = DirMonitor.new('lib')
    yield_results = []
    dm.scan_new do |file|
      yield_results << file
    end
    yield_results.should == known_files
  end
  
  it "should not yield known file names" do
    known_files = %w[lib/minitest.rb lib/dir_monitor.rb]
    known_files2 = %w[lib/minitest.rb lib/dir_monitor2.rb]
    Dir.should_receive(:glob).with('lib/**/*').and_return(known_files, known_files2)
    dm = DirMonitor.new('lib')
    dm.scan
    yield_results = []
    dm.scan_new do |file|
      yield_results << file
    end
    yield_results.should == known_files2 - known_files
  end
end

describe DirMonitor, "#scan_new_with_spec" do
  it "should yield new files and their specs" do
    file = 'lib/dir_monitor.rb'
    spec = 'spec/dir_monitor_spec.rb'
    Dir.should_receive(:glob).with('lib/**/*').and_return([file])
    File.should_receive(:exists?).with(spec).and_return(true)
    dm = DirMonitor.new 'lib'
    results = []
    dm.scan_new_with_spec do |new_file, new_spec|
      results << {new_file => new_spec}
    end
    results.should == [{file=>spec}]
  end
  
  it "should not yield files with non-existent specs" do
    file = 'lib/dir_monitor.rb'
    spec = 'spec/dir_monitor_spec.rb'
    Dir.should_receive(:glob).with('lib/**/*').and_return([file])
    File.should_receive(:exists?).with(spec).and_return(false)
    dm = DirMonitor.new 'lib'
    results = []
    dm.scan_new_with_spec do |new_file, new_spec|
      results << {new_file => new_spec}
    end
    results.should == []
  end
end

describe DirMonitor, "#scan_changed" do
  before(:each) do
    @file = 'lib/dir_monitor.rb'
    @time = Time.now
    Dir.stub!(:glob).with('lib/**/*').and_return([@file])
    File.stub!(:mtime).with(@file).and_return(@time)
    @dm = DirMonitor.new 'lib'
    @dm.scan
  end
  
  it "should yield the names of changed known files" do
    changes = []
    @dm.scan_changed do |changed_file|
      changes << changed_file
    end
    changes.should == [@file]
  end
  
  it "should not yield the names of files which did not change since last scan" do
    @dm.scan_changed { |f| }
    changes = []
    @dm.scan_changed do |changed_file|
      changes << changed_file
    end
    changes.should == []
  end

  it "should yield for every change in a file" do
    # Every scan should find the file changed:
    File.should_receive(:mtime).with(@file).and_return(@time-3,@time-2,@time-1)
    3.times do
      changes = []
      @dm.scan_changed do |changed_file|
        changes << changed_file
      end
      changes.should == [@file]
    end
  end
end

describe DirMonitor, "#spec_for" do
  it "should find the spec for a given file" do
    file = 'lib/dir_monitor.rb'
    spec = 'spec/dir_monitor_spec.rb'
    dm = DirMonitor.new
    dm.spec_for(file).should == spec
  end
  
  it "should find the spec for non-ruby files" do
    file = 'app/views/posts/post.html.haml'
    spec = 'spec/views/posts/post.html.haml_spec.rb'
    dm = DirMonitor.new
    dm.spec_for(file).should == spec
  end
  
  it "should map specs to themselves" do
    spec = 'spec/dir_monitor_spec.rb'
    dm = DirMonitor.new
    dm.spec_for(spec).should == spec
  end
end