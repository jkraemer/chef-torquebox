default[:torquebox][:manage_java_installation] = true
default[:torquebox][:version] = "2.0.2" # Also supported: "2.x.incremental.1103" would download latest incremental build and assume it is 1103 when uncompressing
default[:torquebox][:version_is_incremental_build] = false
default[:torquebox][:checksum] = "34fe9a8cb29456d59048fd2d7e319e27"
default[:torquebox][:jruby][:opts] = "--1.8"
default[:torquebox][:backstage_gitrepo] = "git://github.com/torquebox/backstage.git"
default[:torquebox][:backstage_home] = "/var/www/backstage"
default[:torquebox][:backstage_user] = nil
default[:torquebox][:backstage_password] = nil
default[:torquebox][:log_dir] = "/var/log/torquebox"
default[:torquebox][:bind_to_ip] = "127.0.0.1" # Default IP address to bind to 
default[:torquebox][:bind_to_ip_from_node_attrs] = ["cloud", "local_ipv4"] # Evals to node["cloud"]["local_ipv4"] (internal ec2 IP), overrides :bind_to_ip
default[:torquebox][:ssl][:enabled] = false
default[:torquebox][:ssl][:keystore_path] = ""
default[:torquebox][:ssl][:keystore_alias] = ""
default[:torquebox][:ssl][:keystore_password] = ""
default[:torquebox][:mod_cluster][:enable] = false
default[:torquebox][:mod_cluster][:version] = "1.2.0"

default[:torquebox][:java][:opts]["Xms"] = "384m"
default[:torquebox][:java][:opts]["Xmx"] = "1024m"
default[:torquebox][:java][:opts]["XX:MaxPermSize"] = "512m"
default[:torquebox][:java][:opts]["XX:ReservedCodeCacheSize"] = "128m"

