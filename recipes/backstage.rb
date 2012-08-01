include_recipe "torquebox::default"

execute "jruby -S gem install torquebox-backstage"

if node[:torquebox][:backstage][:user] && node[:torquebox][:backstage][:password]
  execute "jruby -S backstage deploy --secure=#{node[:torquebox][:backstage][:user]}:#{node[:torquebox][:backstage][:password]}"
else
  execute "jruby -S backstage deploy"
end
