require_relative 'base'
require 'vagrant-databags/data_bags'

module VagrantPlugins
  module DataBags
    module Action
      class PersistDataBags < Base

        def initialize(app, env)
          @app = app

          klass = self.class.name.downcase.split('::').last
          @logger = Log4r::Logger.new("vagrant::databags::#{klass}")
        end

        def call(env)
          chef_provisioners = machine_chef_provisioners(env[:machine])

          chef_provisioners.each do |chef|
            if env[:machine].config.databags.map.size > 0
              env[:ui].detail "[vagrant-databags] Persisting temp data bags"
              provisioner_type = chef_provisioner_type(chef)
              DataBagsContainer.instance.persist_machine_data_bags(env[:machine], provisioner_type)
            end
          end

          @app.call(env)
        end

        def recover(env)
          if env[:machine].config.databags.cleanup_on_provision && env[:machine].config.databags.map.size > 0
            env[:ui].detail "[vagrant-databags] Cleaning up temp data bags folder"
            chef_provisioners = machine_chef_provisioners(env[:machine])
            chef_provisioners.each do |chef|
              provisioner_type = chef_provisioner_type(chef)
              DataBagsContainer.instance.clean(env[:machine], provisioner_type)
            end
          end
        end
      end
    end
  end
end