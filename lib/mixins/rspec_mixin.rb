module RspecMixin
  attr_accessor :spec_cmd, :spec_opts

  def spec_opts
    @spec_opts ||= ( File.exist?('spec/spec.opts') ? '-O spec/spec.opts' : '' )
  end

  def specs_to_ignore
    @specs_to_ignore ||= Set.new(%w[spec/spec_helper.rb])
  end

  private

  def find_spec_cmd
    `which spec`.strip
  end

  # Command line string to run rspec for an array of specs. Defaults to all specs.
  def rspec(specs=known_specs)
    "#{spec_cmd} #{specs.join(" ")} #{spec_opts}"
  end

  # The command to use to run specs.
  def spec_cmd
    @spec_cmd ||= ( File.exist?('script/spec') ? 'script/spec' : find_spec_cmd )
  end
end