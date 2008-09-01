require 'set_ext'
require 'dir_monitor'
require 'mixins/rcov_mixin'
require 'mixins/rspec_mixin'

# = Minitest
# The default usage of Minitest is this:
#   minitest = Minitest.new
#   minitest.start
# This will do the following:
# - Initialize a DirMonitor
# - Frequently check for new or changed files; run rspec or test/unit on their associated specs or tests
# - Run rcov (code coverage tester) on all specs when exiting (Press ctrl-C on send SIGINT to the process)
class Minitest
  include RcovMixin
  include RspecMixin

  attr_accessor :source_dirs
  attr_reader   :specs_to_run, :known_specs
  attr_reader   :tests_to_run

  DEFAULT_SOURCE_DIRS = %w[lib app spec test]

  def initialize
    @active = false
    @known_specs = Set.new
    @specs_to_run = Set.new
    @tests_to_run = Set.new
  end

  def active?
    @active == true
  end

  def source_dirs
    @source_dirs || DEFAULT_SOURCE_DIRS
  end

  # Compile list of new or changed files with specs.
  # Execute rspec on their specs.
  def check_specs
    specs_to_run.clear
    @spec_monitor.scan_new_or_changed_with_spec do |file, spec|
      next if specs_to_ignore.include?(spec)
      known_specs << spec
      specs_to_run << spec
    end
    if specs_to_run.size > 0
      print "\nTesting files: #{specs_to_run.join(" ")}\n"
      system rspec(specs_to_run)
    end
  end

  # Compile list of new or changed files with tests.
  # Execute test/unit on the test files.
  def check_tests
    tests_to_run.clear
    @test_monitor.scan_new_or_changed_with_test do |file, test|
      tests_to_run << test
    end
    if tests_to_run.size > 0
      print "\nTesting files: #{tests_to_run.join(" ")}\n"
      system 'ruby -e "" -rtest/unit %s' % tests_to_run.map{|test| '-r%s' % test}.join(" ")
    end
  end

  # Start an infinite loop which does the following:
  # * Check for files to test and test them, both for specs and tests
  # * Sleep for a second
  # Prior to starting the loop, the INT signal is trapped,
  # so interrupting the process will not directly kill it.
  # Instead, RCov is ran on all known specs.
  def start
    @active = true
    @spec_monitor = DirMonitor.new(source_dirs)
    @test_monitor = DirMonitor.new(source_dirs)
    trap_int_for_rcov
    while active? do
      check_specs
      check_tests
      sleep 1
    end
  end

  def trap_int_for_rcov
    Signal.trap("INT") do
      print "\nNow we run rcov and we're done.\n\n"
      specs = known_specs.select{|s| File.exist?(s)}
      puts rcov(specs)
      system rcov(specs)
      @active = false
    end
  end
end
