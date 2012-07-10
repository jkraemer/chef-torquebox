include_recipe "torquebox::server"

execute "jruby -S gem install torquebox-backstage"

if node[:torquebox][:backstage_user] && node[:torquebox][:backstage_password]
  execute "jruby -S backstage deploy --secure=#{node[:torquebox][:backstage_user]}:#{node[:torquebox][:backstage_password]}"
else
  execute "jruby -S backstage deploy"
end
