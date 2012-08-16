include_recipe "torquebox::default"

template "/opt/torquebox/current/jboss/standalone/configuration/standalone.xml" do
  source "standalone.xml.erb"
  owner "torquebox"
  group "torquebox"
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
    :server_config_file => "standalone.xml"
  )
  mode "664"
  notifies :restart, "service[torquebox]", :delayed
end
