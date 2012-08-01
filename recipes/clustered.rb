include_recipe "torquebox::default"

initial_host_ips = []

if node[:torquebox][:clustered][:initial_hosts_role] && node[:torquebox][:clustered][:initial_hosts_attribute]
  # First, get this node's IP so we can ignore it later.
  this_node_ip = node
  node[:torquebox][:clustered][:initial_hosts_attribute].each do |next_key|
    if this_node_ip.has_key?(next_key)
      this_node_ip = this_node_ip[next_key]
    else
      this_node_ip = nil
      break
    end
  end
  
  (search("node", "role:#{node[:torquebox][:clustered][:initial_hosts_role]} AND chef_environment:#{node.chef_environment}") || []).each do |member_node|
    # Look up node IP based on the node attribute specified by the role
    loaded_node_ip = member_node
    node[:torquebox][:clustered][:initial_hosts_attribute].each do |next_key|
      if loaded_node_ip.has_key?(next_key)
        loaded_node_ip = loaded_node_ip[next_key]
      else
        loaded_node_ip = nil
        break
      end
    end
    
    initial_host_ips << loaded_node_ip unless loaded_node_ip == this_node_ip
  end
end

# template "/opt/torquebox/current/jboss/standalone/configuration/standalone-ha.xml" do
template "/opt/torquebox/current/jboss/standalone/configuration/standalone-ha.xml" do
  source "standalone-ha.xml.erb"
  owner "torquebox"
  group "torquebox"
  variables(
    :initial_hosts => initial_host_ips
  )
  mode "644"
  notifies :restart, "service[torquebox]", :delayed
end

template "/opt/torquebox/current/jboss/bin/standalone.conf" do
  source "standalone.conf.erb"
  owner "torquebox"
  group "torquebox"
  variables(
    :jboss_pidfile => "/opt/torquebox/current/jboss/standalone/torquebox.pid",
    :java_opts => node[:torquebox][:server][:java][:opts],
    :server_config_file => "standalone-ha.xml"
  )
  mode "644"
  notifies :restart, "service[torquebox]", :delayed
end

### MOD_CLUSTER STUFF BELOW
# 
# # Create top level mod_cluster directory
# directory "/opt/mod_cluster" do
#   owner "torquebox"
#   group "torquebox"
#   recursive true
#   action :create
# end
# 
# install_from_release('mod_cluster') do
#   release_url   "http://downloads.jboss.org/mod_cluster/#{node[:torquebox][:clustered][:mod_cluster][:version]}.Final/mod_cluster-#{node[:torquebox][:clustered][:mod_cluster][:version]}.Final-linux2-x64-ssl.tar.gz"
#   home_dir      "/opt/mod_cluster/mod_cluster-#{node[:torquebox][:clustered][:mod_cluster][:version]}"
#   action        [:unpack]
#   version       node[:torquebox][:clustered][:mod_cluster][:version]
#   not_if{ File.exists?("/opt/mod_cluster/mod_cluster-#{node[:torquebox][:clustered][:mod_cluster][:version]}") }
# end
# 
# link "/opt/mod_cluster/current" do
#   to "/opt/mod_cluster/mod_cluster-#{node[:torquebox][:clustered][:mod_cluster][:version]}"
# end
# 
# execute "modcluster installhome" do
#   command "/opt/mod_cluster/current/jboss/httpd/sbin/installhome.sh"
#   user "root"
# end
# execute "modcluster (re)start" do
#   command "/opt/mod_cluster/current/jboss/httpd/sbin/apachectl restart"
#   user "root"
# end