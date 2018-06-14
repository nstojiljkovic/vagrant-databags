require 'vagrant-databags/data_bags'

module VagrantPlugins
  module DataBags
    module Action
      class Base
        def initialize(app, env)
          @app = app

          klass = self.class.name.downcase.split('::').last
          @logger = Log4r::Logger.new("vagrant::databags::#{klass}")
        end

        def machine_chef_provisioners(machine)
          machine.config.vm.provisioners.select do |provisioner|
            # Vagrant 1.7 changes provisioner.name to provisioner.type
            if provisioner.respond_to? :type
              provisioner.type.to_sym == :chef_solo || provisioner.type.to_sym == :chef_zero
            else
              provisioner.name.to_sym == :chef_solo || provisioner.name.to_sym == :chef_zero
            end
          end
        end

        def chef_provisioner_type(chef)
          if chef.respond_to? :type
            provisioner_type = chef.type.to_sym
          else
            provisioner_type = chef.name.to_sym
          end
          provisioner_type
        end
      end
    end
  end
end
