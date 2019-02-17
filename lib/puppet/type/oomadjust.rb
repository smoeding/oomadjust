# oomadjust.rb --- Type for the oomadjust provider

require 'puppet/parameter/boolean'

Puppet::Type.newtype(:oomadjust) do
  @doc = %q{Reduce the likelihood of an OOM for a process by setting the
    OOM adjustement score. The type uses the newer *oom_score_adj*
    interface if that is implemented by the kernel.

    Example:

      oomadjust { 'rsyslogd': }

      oomadjust { 'rsyslogd':
        legacy     => true,
        adjustment => '-10',
      }

      oomadjust { 'rsyslogd':
        pidfile => '/var/run/rsyslogd.pid',
      }
  }

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name) do
    desc %q{The (process) name used to locate the PID file. Default is the
       resource title.}

    newvalues(/^[a-zA-Z0-9_-]+$/)
  end

  newparam(:pidfile) do
    desc %q{The pidfile for the process. This must be an absolute pathname.
      Default is /var/run/PROCESS.pid where PROCESS is the value of
      the :name parameter or the resource title if :name is not set.}

    defaultto { "/var/run/#{@resource[:name]}.pid" }

    validate do |value|
      unless Pathname.new(value).absolute?
        raise ArgumentError, "File #{value} must be an absolute path"
      end
      unless File.exists?(value)
        raise ArgumentError, "File #{value} does not exist"
      end
    end
  end

  newparam(:legacy, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc %q{Should the legacy kernel interface be used. This defaults to
      'true' if only the older interface is available and 'false'
      otherwise.}

    newvalues(:true, :false)
    defaultto { !File.exists?('/proc/self/oom_score_adj') }
  end

  newproperty(:adjustment) do
    desc %q{The adjustment to set. This can range from -17..15 for the legacy
      interface and from -1000..1000 for the default kernel interface.
      Smaller values make it less likely that the process is terminated
      as the result of an OOM condition. Setting a value of -17/-1000
      should normally inhibit the process from being terminated. The
      default value is '-17'/'-1000' depending on the *legacy* param.}

    newvalues(/^-?[1-9][0-9]*$/)
    defaultto { (File.exists?('/proc/self/oom_score_adj') ? '-1000' : '-17') }
  end

  validate do
    if self[:legacy]
      unless self[:adjustment].to_i.between?(-17, 15)
        raise ArgumentError, "Adjustment must be in range -17..15"
      end
    else
      unless self[:adjustment].to_i.between?(-1000, 1000)
        raise ArgumentError, "Adjustment must be in range -1000..1000"
      end
    end
  end

  autorequire(:service) do
    self[:name]
  end
end
