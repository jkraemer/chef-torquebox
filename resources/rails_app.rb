actions :deploy, :undeploy

attribute :name, :kind_of => String, :name_attribute => true
attribute :install_in, :kind_of => String, :default => "/var/www"
attribute :git_repository, :kind_of => String, :required => true
attribute :configuration, :kind_of => Hash, :default => {}