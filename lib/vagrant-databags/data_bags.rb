require 'json'
require 'singleton'
require 'vagrant-databags/file_util'

module VagrantPlugins
  module DataBags

    class DataBagsContainer
      include Singleton
      include FileUtil

      # @return [Hash<Symbol, Hash<Symbol, MachineDataBags>>]
      attr_accessor :machine_data_bags

      # @return [Array<String>]
      attr_reader :temp_folders

      def initialize
        @machine_data_bags_map = {}
      end

      # @param [::Vagrant::Machine] machine
      # @param [Symbol] provisioner_type
      # @param [Array<String>] data_bags_path
      # @return [MachineDataBags]
      def init_machine_data_bags(machine, provisioner_type, data_bags_path)
        machine_data_bags = get_machine_data_bags(machine, provisioner_type)
        data_bags_path.each do |data_bag_path|
          if data_bag_path[0] == :host
            data_bags_root_path = ::File.absolute_path(data_bag_path[1], machine.env.root_path)
            find_all_object_dirs(data_bags_root_path).each do |data_bag_name|
              find_all_objects(::File.join(data_bags_root_path, data_bag_name)).each do |item_file_name|
                item = object_from_json_file(::File.join(data_bags_root_path, data_bag_name, item_file_name))
                machine_data_bags.add_data_bag_item(data_bag_name, item['id'], item)
              end
            end
          end
        end
        @machine_data_bags_map[machine.name.to_sym][provisioner_type.to_sym] = machine_data_bags
        machine_data_bags
      end

      # @param [::Vagrant::Machine] machine
      # @param [Symbol] provisioner_type
      # @return [MachineDataBags]
      def get_machine_data_bags(machine, provisioner_type)
        unless @machine_data_bags_map.key?(machine.name.to_sym)
          @machine_data_bags_map[machine.name.to_sym] = {}
        end
        unless @machine_data_bags_map[machine.name.to_sym].key?(provisioner_type.to_sym)
          @machine_data_bags_map[machine.name.to_sym][provisioner_type.to_sym] = MachineDataBags.new
        end

        @machine_data_bags_map[machine.name.to_sym][provisioner_type.to_sym]
      end

      # @param [::Vagrant::Machine] machine
      # @param [Symbol] provisioner_type
      # @return [Array]
      def init_machine_data_bag_folder(machine, provisioner_type)
        rel_temp_folder = get_rel_temp_folder(machine, provisioner_type)
        ::FileUtils.mkdir_p ::File.join(machine.env.root_path, rel_temp_folder)
        [:host, rel_temp_folder]
      end

      # @param [::Vagrant::Machine] machine
      # @param [Symbol] provisioner_type
      # @return [Array]
      def persist_machine_data_bags(machine, provisioner_type)
        machine_data_bags = get_machine_data_bags(machine, provisioner_type)
        rel_temp_folder = get_rel_temp_folder(machine, provisioner_type)
        temp_folder = ::File.join(machine.env.root_path, rel_temp_folder)

        machine_data_bags.data_bags.each do |data_bag_name, data_bag|
          data_bag_folder = ::File.join(temp_folder, data_bag_name)
          ::FileUtils.mkdir_p data_bag_folder
          data_bag.items.each do |item_id, item|
            open(File.join(data_bag_folder, "#{item_id}.json"), 'w') {|f| f << ::JSON.pretty_generate(item)}
          end

          find_all_objects(data_bag_folder).each do |file_name|
            item_id = ::File.basename(file_name, ".*")
            unless data_bag.items.key?(item_id) || data_bag.items.key?(item_id.to_sym)
              ::FileUtils.rm_r ::File.join(data_bag_folder, file_name), :force => true
            end
          end
        end

        find_all_object_dirs(temp_folder).each do |folder_name|
          unless machine_data_bags.data_bags.key?(folder_name)
            ::FileUtils.rm_r ::File.join(temp_folder, folder_name), :force => true
          end
        end
        [:host, rel_temp_folder]
      end

      # @param [::Vagrant::Machine] machine
      def destroy(machine)
        ::FileUtils.rm_r get_abs_temp_folder(machine), :force => true
      end

      # @param [::Vagrant::Machine] machine
      # @param [Symbol] provisioner_type
      def clean(machine, provisioner_type)
        abs_temp_folder = get_abs_temp_folder(machine, provisioner_type)
        Dir[::File.join(abs_temp_folder, "*")].each do |f|
          ::FileUtils.rm_r f, :force => true
        end
      end

      # @param [::Vagrant::Machine] machine
      # @param [Symbol] provisioner_type
      # @return [String]
      def get_abs_temp_folder(machine, provisioner_type = nil)
        ::File.join(machine.env.root_path, get_rel_temp_folder(machine, provisioner_type))
      end

      # @param [::Vagrant::Machine] machine
      # @param [Symbol] provisioner_type
      # @return [String]
      def get_rel_temp_folder(machine, provisioner_type = nil)
        if provisioner_type.nil?
          ::File.join(".vagrant", "machines", machine.name.to_s, "databags")
        else
          ::File.join(".vagrant", "machines", machine.name.to_s, "databags", provisioner_type.to_s)
        end
      end
    end

    class MachineDataBags
      # @return [Hash<String, DataBag>]
      attr_accessor :data_bags

      def initialize
        @data_bags = {}
      end

      # @param [String] data_bag_name
      # @param [String] item_id
      # @param [Hash] item
      def add_data_bag_item(data_bag_name, item_id, item)
        get_data_bag(data_bag_name).add_item(item_id, item)
      end

      # @param [String] data_bag_name
      # @return [DataBag]
      def get_data_bag(data_bag_name)
        unless @data_bags.key?(data_bag_name)
          @data_bags[data_bag_name] = DataBag.new(data_bag_name)
        end
        @data_bags[data_bag_name]
      end

      # @return [Array<String>]
      def data_bag_names
        @data_bags.keys
      end
    end

    class DataBag
      # @return [String]
      attr_reader :name

      # @return [Hash<String, Object>]
      attr_accessor :items

      def initialize(name)
        @name = name
        @items = {}
      end

      def add_item(item_id, item)
        @items[item_id] = item
      end
    end

  end
end
