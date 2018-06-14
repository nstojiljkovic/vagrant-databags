require 'vagrant-databags/config'
require 'vagrant-databags/version'

module VagrantPlugins
  module DataBags
    class Plugin < Vagrant.plugin(2)
      name 'DataBags Plugin'

      [:machine_action_up, :machine_action_reload, :machine_action_provision].each do |action|
        action_hook(:databags_provision, action) do |hook|
          # hook.after Vagrant::Action::Builtin::ConfigValidate, Action::LoadDataBags
          hook.before Vagrant::Action::Builtin::Provision, Action::LoadDataBags
        end
      end

      action_hook(:databags_provision, :provisioner_run) do |hook|
        hook.before :run_provisioner, Action::PersistDataBags
        hook.after :run_provisioner, Action::CleanDataBags
      end

      action_hook(:databags_provision, :machine_action_destroy) do |hook|
          hook.before Vagrant::Action::Builtin::ProvisionerCleanup, Action::DestroyDataBags
          # hook.before Vagrant::Action::Builtin::DestroyConfirm, Plugin.provisioner_destroy
      end

      config(:databags) do
        require_relative 'config'
        Config
      end
    end
  end
end
