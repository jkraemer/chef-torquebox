default[:torquebox][:manage_java_installation] = true
default[:torquebox][:version] = "2.0.2"
default[:torquebox][:checksum] = "34fe9a8cb29456d59048fd2d7e319e27"
default[:torquebox][:jruby][:opts] = "--1.8"
default[:torquebox][:backstage_gitrepo] = "git://github.com/torquebox/backstage.git"
default[:torquebox][:backstage_home] = "/var/www/backstage"
default[:torquebox][:log_dir] = "/var/log/torquebox"
default[:torquebox][:bind_to_ip] = "127.0.0.1" # Default IP address to bind to 
default[:torquebox][:bind_to_ip_from_node_attrs] = ["cloud", "local_ipv4"] # Evals to node["cloud"]["local_ipv4"] (internal ec2 IP), overrides :bind_to_ip
default[:torquebox][:ssl][:enabled] = false
default[:torquebox][:ssl][:keystore_path] = ""
default[:torquebox][:ssl][:keystore_alias] = ""
default[:torquebox][:ssl][:keystore_password] = ""

