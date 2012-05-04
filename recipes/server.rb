include_recipe "java::default" if node[:torquebox][:manage_java_installation]

version = node[:torquebox][:version]

user "torquebox" do
  comment "torquebox"
  home "/home/torquebox"
  supports :manage_home => true
end

tb_tld = "/opt/torquebox"
prefix = "#{tb_tld}/torquebox-#{version}"
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

install_from_release('torquebox') do
  release_url   node[:torquebox][:url]
  home_dir      prefix
  action        [:install, :install_binaries]
  version       version
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

execute "chown torquebox in /usr" do
  command "chown -R torquebox:torquebox /usr/local/share/torquebox-#{version}"
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
