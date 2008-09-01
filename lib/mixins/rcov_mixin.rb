module RcovMixin
  DEFAULT_RCOV_IGNORES = %w[spec/ db/ plugins/ vendor/ config/]
  attr_accessor :rcov_ignores

  # Partial filepaths to exclude from rcov output
  def rcov_ignores
    ignores = (@rcov_ignores || DEFAULT_RCOV_IGNORES).dup
    ignores << spec_cmd
    ignores.join(",")
  end

  private

  def find_rcov_cmd
    `which rcov`.strip
  end

  # Command line string to run rcov for all monitored specs.
  def rcov
    "#{rcov_cmd} -T --exclude \"#{rcov_ignores}\" -Ilib #{spec_cmd} -- " + known_specs.select{|s| File.exist?(s)}.join(" ")
  end

  def rcov_cmd
    @rcov_cmd ||= find_rcov_cmd
  end

  def trap_int_for_rcov
    Signal.trap("INT") do
      print "\nNow we run rcov and we're done.\n\n"
      puts rcov
      system rcov
      @active = false
    end
  end
end