def initialize(*args)
  super
  
  package "git-core"
end

action :deploy do
  directory "#{new_resource.install_in}" do
    recursive true
    owner "torquebox"
    group "torquebox"
  end
  
  git "application:#{new_resource.name}" do
    repository new_resource.git_repository
    revision "HEAD"
    destination "#{new_resource.install_in}/#{new_resource.name}"
    action :sync
    user "torquebox"
    group "torquebox"
  end
  
  # Construct/clobber the YAML file
  require "yaml"
  file "#{new_resource.install_in}/#{new_resource.name}/config/torquebox.yml" do
    content new_resource.configuration.to_yaml
  end
  
  execute "bundle install" do
    command "jruby -S bundle install"
    cwd "#{new_resource.install_in}/#{new_resource.name}"
    not_if "jruby -S bundle check"
  end
  
  # Takes way too long
  # execute "compile assets" do
  #   command "jruby -S bundle exec rake assets:precompile"
  #   cwd "#{new_resource.install_in}/#{new_resource.name}"
  #   environment "RAILS_ENV" => "production", "JRUBY_OPTS" => node[:torquebox][:jruby][:opts]
  # end
  
  torquebox_application "tb_app:#{new_resource.name}" do
    action :deploy
    path "#{new_resource.install_in}/#{new_resource.name}"
  end
end

action :undeploy do
  torquebox_application "tb_app:#{new_resource.name}" do
    action :undeploy
    path "#{new_resource.install_in}/#{new_resource.name}"
  end
end
