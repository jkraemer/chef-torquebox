#include_recipe "java::default" if node[:torquebox][:manage_java_installation]
# Install manually until this is fixed: http://tickets.opscode.com/browse/COOK-1497; this fix will only work on ubuntu
if node[:torquebox][:manage_java_installation]
  package "openjdk-6-jdk"
  ENV['JAVA_HOME'] = "/usr/lib/jvm/java-1.6.0-openjdk-amd64" # assumes 64-bit
end

version = node[:torquebox][:version]
canonical_version = node[:torquebox][:version_is_incremental_build] ? "2.x.incremental.#{node[:torquebox][:version]}" : node[:torquebox][:version]

user "torquebox" do
  comment "torquebox"
  home "/home/torquebox"
  supports :manage_home => true
end

tb_tld = "/opt/torquebox"
prefix = "#{tb_tld}/torquebox-#{canonical_version}"
current = "#{tb_tld}/current"

# Create top level torquebox directory
directory "#{tb_tld}" do
  owner "torquebox"
  group "torquebox"
  recursive true
  action :create
end

ENV['TORQUEBOX_HOME'] = current
ENV['JBOSS_HOME'] = "#{current}/jboss"
ENV['JRUBY_HOME'] = "#{current}/jruby"
ENV['PATH'] = "#{ENV['PATH']}:#{ENV['JRUBY_HOME']}/bin"

package "unzip"
package "upstart"

tb_url = node[:torquebox][:version_is_incremental_build] ? 
  "http://repository-projectodd.forge.cloudbees.com/incremental/torquebox/#{node[:torquebox][:version]}/torquebox-dist-bin.zip"
  :
  "http://torquebox.org/release/org/torquebox/torquebox-dist/#{node[:torquebox][:version]}/torquebox-dist-#{node[:torquebox][:version]}-bin.zip"

install_from_release('torquebox') do
  release_url   tb_url
  home_dir      prefix
  action        [:install, :install_binaries]
  version       canonical_version
  checksum      node[:torquebox][:checksum]
  not_if{ File.exists?(prefix) }
end

template "/etc/profile.d/torquebox.sh" do
  mode "755"
  source "torquebox.erb"
end

link current do
  to prefix
end

# install upstart & get it running
execute "torquebox-upstart" do
  command "jruby -S rake torquebox:upstart:install"
  creates "/etc/init/torquebox.conf"
  cwd current
  action :run
  environment ({
    'TORQUEBOX_HOME'=> current,
    'JBOSS_HOME'=> "#{current}/jboss",
    'JRUBY_HOME'=> "#{current}jruby",
    'PATH' => "#{ENV['PATH']}:#{current}/jruby/bin"
  })
end

# Look up each successive element in the node hash to find the ip address to bind to.
if node[:torquebox][:bind_to_ip_from_node_attrs]
  last_value = node
  node[:torquebox][:bind_to_ip_from_node_attrs].each do |next_key|
    if last_value.has_key?(next_key)
      last_value = last_value[next_key]
    else
      last_value = nil
      break
    end
  end
end

# Configure the ip bind options for the template that follows.
bind_opts = ""
if last_value
  bind_opts = "-b #{last_value}"
elsif node[:torquebox][:bind_to_ip]
  bind_opts = "-b #{node[:torquebox][:bind_to_ip]}"
else
  bind_opts = ""
end

# Replace the upstart/configuration file.
template "/etc/init/torquebox.conf" do
  source "torquebox.conf.erb"
  owner "root"
  group "root"
  mode "644"
  variables :bind_opts => bind_opts, :torquebox_dir => current
end

# Replace the standalone script
template "#{current}/jboss/bin/standalone.conf" do
  source "standalone.conf.erb"
  owner "torquebox"
  group "torquebox"
  variables(
    :jboss_pidfile => "#{current}/jboss/standalone/torquebox.pid",
    :java_opts => node[:torquebox][:server][:java][:opts]
  )
  mode "644"
end

if node[:torquebox][:mod_cluster][:enable]
  cluster_tld = "/opt/mod_cluster"
  cluster_prefix = "#{cluster_tld}/mod_cluster-#{canonical_version}"
  cluster_current = "#{cluster_tld}/current"
  
  # Create top level mod_cluster directory
  directory "#{cluster_tld}" do
    owner "torquebox"
    group "torquebox"
    recursive true
    action :create
  end
  
  install_from_release('mod_cluster') do
    release_url   "http://downloads.jboss.org/mod_cluster/#{node[:torquebox][:mod_cluster][:version]}.Final/mod_cluster-#{node[:torquebox][:mod_cluster][:version]}.Final-linux2-x64-ssl.tar.gz"
    home_dir      cluster_prefix
    action        [:unpack]
    version       node[:torquebox][:mod_cluster][:version]
    not_if{ File.exists?(cluster_prefix) }
  end
  
  link cluster_current do
    to cluster_prefix
  end
  
  execute "modcluster installhome" do
    command "#{cluster_current}/jboss/httpd/sbin/installhome.sh"
    user "root"
  end
  execute "modcluster (re)start" do
    command "#{cluster_current}/jboss/httpd/sbin/apachectl restart"
    user "root"
  end
  
  template "#{current}/jboss/standalone/configuration/standalone.xml" do
    source "standalone.xml.erb"
    owner "torquebox"
    group "torquebox"
    mode "644"
  end
else
  template "#{current}/jboss/standalone/configuration/standalone.xml" do
    source "standalone.xml.erb"
    owner "torquebox"
    group "torquebox"
    mode "644"
  end
end

execute "chown torquebox in /usr" do
  command "chown -R torquebox:torquebox /usr/local/share/torquebox-#{canonical_version}"
end

service "torquebox" do
  provider Chef::Provider::Service::Upstart
  action [:enable, :start]
end

# otherwise bundler won't work in jruby
gem_package 'jruby-openssl' do
  gem_binary "#{current}/jruby/bin/jgem"
end

#allows use of 'torquebox' command through sudo
cookbook_file "/etc/sudoers.d/torquebox" do
  source 'sudoers'
  owner 'root'
  group 'root'
  mode '0440'
end
