module RspecMixin
  attr_accessor :spec_cmd, :spec_opts
  DEFAULT_SPECS_TO_IGNORE = %w[spec/spec_helper.rb]

  def spec_opts
    @spec_opts ||= ( File.exist?('spec/spec.opts') ? '-O spec/spec.opts' : '' )
  end

  def specs_to_ignore
    @specs_to_ignore ||= Set.new(DEFAULT_SPECS_TO_IGNORE)
  end

  # Command line string to run rspec for an array of specs. Defaults to all specs.
  def rspec(specs)
    "#{spec_cmd} #{specs.join(" ")} #{spec_opts}"
  end

  private

  def find_spec_cmd
    `which spec`.strip
  end

  # The command to use to run specs.
  def spec_cmd
    @spec_cmd ||= ( File.exist?('script/spec') ? 'script/spec' : find_spec_cmd )
  end
end