default[:torquebox][:manage_java_installation] = true
default[:torquebox][:version] = "2.0.2"
default[:torquebox][:url] = "http://torquebox.org/release/org/torquebox/torquebox-dist/#{node[:torquebox][:version]}/torquebox-dist-#{node[:torquebox][:version]}-bin.zip"
default[:torquebox][:checksum] = "34fe9a8cb29456d59048fd2d7e319e27"
default[:torquebox][:jruby][:opts] = "--1.8"
default[:torquebox][:backstage_gitrepo] = "git://github.com/torquebox/backstage.git"
default[:torquebox][:backstage_home] = "/var/www/backstage"
