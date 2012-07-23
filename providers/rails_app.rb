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
  
  # Need to get/set these variables because new_resource won't be available once we're in a different lwrp (timestamped_deploy)
  app_configuration = new_resource.configuration
  app_name = new_resource.name
  app_install_in = new_resource.install_in
  
  timestamped_deploy "#{new_resource.install_in}/#{new_resource.name}" do
    scm_provider Chef::Provider::Git
    repo new_resource.git_repository
    branch "master"
    revision "HEAD"
    user "torquebox"
    group "torquebox"
    enable_submodules false
    shallow_clone true
    
    environment "RACK_ENV" => "production", "JRUBY_OPTS" => node[:torquebox][:jruby][:opts]
    
    before_migrate do
      execute "jruby -S gem install bundler" do
        cwd release_path
      end
      execute "jruby -J-Xmx2048m -J-Xms512m -J-Xmn128m -S bundle install --without development test --deployment" do
        cwd release_path
      end
    end
    
    migrate true
    migration_command "jruby -S bundle exec rake db:migrate"
    
    # This should probably be in a pre_symlink_to_current_directory callback, but chef gives us none.
    # It's safe because our torquebox deploy runs later anyway, but it would be problematic if we were
    # hosting live files from the new release before its assets were compiled.
    before_restart do
      execute "compile assets" do
        user "torquebox"
        group "torquebox"
        cwd release_path
        command "jruby -J-Xmx2048m -J-Xms512m -J-Xmn128m -S bundle exec rake assets:precompile"
        environment "RACK_ENV" => "production", "JRUBY_OPTS" => node[:torquebox][:jruby][:opts]
      end
    end
    
    restart_command do
      # Construct/clobber the YAML file
      require "yaml"
      file "#{release_path}/config/torquebox.yml" do
        content app_configuration.to_yaml
      end

      # Deploy to Torquebox
      torquebox_application "tb_app:#{app_name}" do
        action :deploy
        path "#{app_install_in}/#{app_name}/current"
      end
    end
    
    purge_before_symlink %w{}
    create_dirs_before_symlink %w{}
    symlinks Hash.new # {} doesn't work, as it gets parsed as a block
    symlink_before_migrate Hash.new
    
    action :deploy
  end
  
  # This should probably go in the restart command, but chef does not provide a way to access a top level provider's
  # attributes while nested within a second provider. Since restart runs last anyway, it's easy to just do it here.
  
  
end

action :undeploy do
  torquebox_application "tb_app:#{new_resource.name}" do
    action :undeploy
    path "#{deployed_path}"
  end
end
