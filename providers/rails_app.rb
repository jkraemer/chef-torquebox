def initialize(*args)
  super
  
  package "git-core"
end

action :deploy do
  directory "#{new_resource.install_in}/#{new_resource.name}" do
    recursive true
    owner "torquebox"
    group "torquebox"
  end
  
  timestamped_deploy "#{new_resource.install_in}/#{new_resource.name}" do
    scm_provider Chef::Provider::Git
    repo new_resource.git_repository
    revision new_resource.git_revision
    user "torquebox"
    group "torquebox"
    enable_submodules false
    shallow_clone true
    
    environment "RACK_ENV" => new_resource.configuration["environment"]["RACK_ENV"], "JRUBY_OPTS" => node[:torquebox][:jruby][:opts]

    migrate false
    purge_before_symlink %w{}
    create_dirs_before_symlink %w{}
    symlinks Hash.new # {} doesn't work, as it gets parsed as a block
    symlink_before_migrate Hash.new
    
    action :deploy
  end
  
  # By standard Chef practices, the following pieces would be executed within the timestamped_deploy LWRP. I've done them
  # afterwords for two reasons:
  # 1. We make use of nested resources, and as of Chef 10.12, there is no way for nested resources to access their
  #    parents' attributes.
  # 2. Jruby commands within the timestamped_deploy resource were failing when run via "knife ssh", which runs a ptty
  #    session rather than a tty session. Even when I set the environment variables manually I was getting errors
  #    finding gems.
  # Because torquebox manages its deploys independently of the Chef timestamped_deploy LWRP, it is easier to do all of
  # this work after the file system is deployed, and then hand it off to Chef. -RG 07/24/2012
  
  app_environment = {
    "RACK_ENV" => new_resource.configuration["environment"]["RACK_ENV"],
    "JRUBY_OPTS" => node[:torquebox][:jruby][:opts]
  }
  app_directory = "#{new_resource.install_in}/#{new_resource.name}/current"
  
  # Vendor the gems
  execute "jruby -S bundle install --without development test --deployment" do
    user "torquebox"
    group "torquebox"
    cwd app_directory
    environment app_environment
  end
  
  # Run database migrations
  execute "jruby -S bundle exec rake db:migrate" do
    user "torquebox"
    group "torquebox"
    cwd app_directory
    environment app_environment
  end
  
  # Precompile asset pipeline assets
  execute "jruby -S bundle exec rake assets:precompile" do
    user "torquebox"
    group "torquebox"
    cwd app_directory
    environment app_environment
  end
  
  # Construct/clobber the YAML file
  require "yaml"
  file "#{app_directory}/config/torquebox.yml" do
    content new_resource.configuration.to_yaml
  end
  
  # Deploy to Torquebox
  torquebox_application "tb_app:#{new_resource.name}" do
    action :deploy
    path app_directory
  end
  
end

action :undeploy do
  torquebox_application "tb_app:#{new_resource.name}" do
    action :undeploy
    path "#{deployed_path}"
  end
end
