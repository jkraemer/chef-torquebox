#
# Cookbook Name:: torquebox
# Recipe:: default
# Description:: Installs torquebox
#
# Copyright 2012, Robby Grossman
#
# MIT Licensed, or any other license you want
#

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

# Create top level torquebox directory
directory "/opt/torquebox" do
  owner "torquebox"
  group "torquebox"
  recursive true
  action :create
end

ENV['TORQUEBOX_HOME'] = "/opt/torquebox/current"
ENV['JBOSS_HOME'] = "/opt/torquebox/current/jboss"
ENV['JRUBY_HOME'] = "/opt/torquebox/current/jruby"
ENV['PATH'] = "#{ENV['PATH']}:#{ENV['JRUBY_HOME']}/bin"

package "unzip"
package "upstart"

tb_url = node[:torquebox][:version_is_incremental_build] ? 
  "http://repository-projectodd.forge.cloudbees.com/incremental/torquebox/#{node[:torquebox][:version]}/torquebox-dist-bin.zip"
  :
  "http://torquebox.org/release/org/torquebox/torquebox-dist/#{node[:torquebox][:version]}/torquebox-dist-#{node[:torquebox][:version]}-bin.zip"

install_from_release('torquebox') do
  release_url   tb_url
  home_dir      "/opt/torquebox/torquebox-#{canonical_version}"
  action        [:install, :install_binaries]
  version       canonical_version
  checksum      node[:torquebox][:checksum]
  not_if{ File.exists?("/opt/torquebox/torquebox-#{canonical_version}") }
end

template "/etc/profile.d/torquebox.sh" do
  mode "755"
  source "torquebox.erb"
end

link "/opt/torquebox/current" do
  to "/opt/torquebox/torquebox-#{canonical_version}"
end

# install upstart & get it running
execute "torquebox-upstart" do
  command "jruby -S rake torquebox:upstart:install"
  creates "/etc/init/torquebox.conf"
  cwd "/opt/torquebox/current"
  action :run
  environment ({
    'TORQUEBOX_HOME'=> "/opt/torquebox/current",
    'JBOSS_HOME'=> "/opt/torquebox/current/jboss",
    'JRUBY_HOME'=> "/opt/torquebox/current/jruby",
    'PATH' => "#{ENV['PATH']}:/opt/torquebox/current/jruby/bin"
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

# Configure the ip bind options for the upstart template.
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
  variables :bind_opts => bind_opts, :torquebox_dir => "/opt/torquebox/current"
  notifies :restart, "service[torquebox]", :delayed
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
  gem_binary "/opt/torquebox/current/jruby/bin/jgem"
end

#allows use of 'torquebox' command through sudo
cookbook_file "/etc/sudoers.d/torquebox" do
  source 'sudoers'
  owner 'root'
  group 'root'
  mode '0440'
end
