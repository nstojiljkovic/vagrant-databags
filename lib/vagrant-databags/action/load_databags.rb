require_relative 'base'
require 'vagrant-databags/data_bags'

module VagrantPlugins
  module DataBags
    module Action
      class LoadDataBags < Base

        def call(env)
          unless env.key?(:data_bags)
            env[:data_bags] = {}
            if env[:machine].config.databags.map.size > 0
              chef_provisioners = machine_chef_provisioners(env[:machine])

              chef_provisioners.each do |chef|
                provisioner_type = chef_provisioner_type(chef)
                env[:ui].detail "[vagrant-databags] Initializing temp data bags folder for provisioner #{provisioner_type}"
                DataBagsContainer.instance.init_machine_data_bags(env[:machine], provisioner_type, chef.config.data_bags_path)
                chef.config.data_bags_path = (chef.config.data_bags_path || []).select {|item| item[0].to_sym != :host}
                chef.config.data_bags_path << DataBagsContainer.instance.init_machine_data_bag_folder(env[:machine], provisioner_type)
                @logger.debug "Setting data_bags_path = #{chef.config.data_bags_path}"

                env[:ui].detail "[vagrant-databags] Evaluating data bags for provisioner #{provisioner_type}"
                # @type [MachineDataBags]
                machine_data_bags = DataBagsContainer.instance.get_machine_data_bags(env[:machine], provisioner_type)

                env[:machine].config.databags.map.each do |data_bag_name, callback|
                  begin
                    new_data_bag_items = callback.call(machine_data_bags.get_data_bag(data_bag_name.to_s).items, env)

                    unless new_data_bag_items.kind_of?(Hash)
                      env[:ui].error "Could not evaluate items of the data bag #{data_bag_name}!"
                      env[:interrupted] = true
                    end
                  rescue Exception => e
                    env[:ui].error "Failed while evaluating items of the data bag #{data_bag_name} with error: #{e}"
                    env[:interrupted] = true
                  end
                end

                env[:data_bags][provisioner_type.to_sym] = {}
                machine_data_bags.data_bag_names.each do |data_bag_name|
                  env[:data_bags][provisioner_type.to_sym][data_bag_name.to_sym] = machine_data_bags.get_data_bag(data_bag_name).items
                end
              end
            end
          end

          @app.call(env)
        end

      end
    end
  end
end
