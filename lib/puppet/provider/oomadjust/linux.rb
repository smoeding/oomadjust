# linux.rb --- Linux provider for oomadjust type

Puppet::Type.type(:oomadjust).provide(:linux) do
  desc %q{Manage the OOM adjustment for a process given by a PID file.}

  confine :kernel => :linux

  # Read a value (the first line) from a file, catch all errors
  #
  def value_in_file(file)
    File.open(file, &:readline).chomp
  rescue
    nil
  end

  # Get the name of the file where the kernel keeps the OOM adjustment value
  #
  def adjfile
    Puppet.debug("Reading PID from file #{resource[:pidfile]}")
    pid = value_in_file(resource[:pidfile])

    return 'undefined' if pid.nil?

    file = "/proc/#{pid}/" + (resource[:legacy] ? "oom_adj" : "oom_score_adj")
    Puppet.debug("Using OOM adjustment for PID #{pid} in #{file}")

    file
  end

  # Get the adjustment value
  #
  def adjustment
    value = value_in_file(adjfile())

    Puppet.debug("OOM adjustment for #{resource[:name]} is #{value}")

    value
  end

  # Set the adjustment value
  #
  def adjustment=(value)
    file = adjfile()

    Puppet.debug("Setting OOM adjustment for process '#{resource[:name]}' to '#{resource[:adjustment]}' in #{file}")

    File.open(file, 'w') { |f| f.write(resource[:adjustment]) }
  end

  # Does the resource exist?
  #
  # We can't really create or remove the file with the adjustment value
  # because it is managed by the Linux kernel. So we simply return the
  # desired state to tell Puppet that everything is just fine.
  def exists?
    resource[:ensure]
  end
end
