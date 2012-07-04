# This is an optional recipe that provides monit monitoring of your riak node. Requires the monit cookbook.

include_recipe "monit::default"

monitrc "torquebox" do
  variables(
    :web_host => node[:cloud][:local_ipv4],
    :web_port => "8080"
  )
  template_source "torquebox-monit.conf.erb"
  template_cookbook "torquebox"
end
