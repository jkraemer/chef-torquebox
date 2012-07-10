deployments = "/opt/torquebox/current/jboss/standalone/deployments"

def initialize(*args)
  super
  @action ||= :deploy
end

action :deploy do
  execute "torquebox archive #{new_resource.path}" do
    cwd "#{new_resource.path}/../../"
  end
  execute "torquebox deploy #{new_resource.path}.knob" do
    creates "#{deployments}/#{new_resource.name}.knob-knob.yml.deployed"
  end
end

action :undeploy do
  execute "torquebox undeploy #{new_resource.path}" do
    creates "#{deployments}/#{new_resource.name}.knob-knob.yml.undeployed"
  end
end
                                                                                