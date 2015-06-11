class puppet_agent::windows::install {

  $_arch = $::kernelmajversion ?{
    /^5\.\d+/ => 'x86', # x64 is never allowed on windows 2003
    default   => $::puppet_agent::arch,
  }

  $_source = $::puppet_agent::source ? {
    undef   => "https://downloads.puppetlabs.com/windows/puppet-agent-${_arch}-latest.msi",
    default => $::puppet_agent::source,
  }

  $_msi_location = $_source ? {
    /^puppet:/ => "${env_temp_variable}\\puppet-agent.msi",
    default    => $_source,
  }

  if $_source =~ /^puppet:/ {
    file{ $_msi_location:
      source => $_source,
      before => File["${env_temp_variable}\\install_puppet.bat"],
    }
  }

  $_timestamp = strftime('%Y_%m_%d-%H_%M')
  $_logfile = "${env_temp_variable}\\puppet-${_timestamp}-installer.log"
  notice ("Puppet upgrade log file at ${_logfile}")
  debug ("Installing puppet from ${_msi_location}")
  file { "${env_temp_variable}\\install_puppet.bat":
    ensure  => file,
    content => template('puppet_agent/install_puppet.bat.erb')
  }->
  exec { 'install_puppet.bat':
    command   => "${::system32}\\cmd.exe /c start /b ${::system32}\\cmd.exe /c \"${env_temp_variable}\\install_puppet.bat\"",
    path      => $::path,
  }
}
