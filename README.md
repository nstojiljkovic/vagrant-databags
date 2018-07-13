# Vagrant DataBags Plugin

Vagrant DataBags is a Vagrant plugin that allows dynamic modification of host-served data bags for the Chef provisioners 
(Chef Solo and Chef Zero).

The primarily goal of this plugin is to ease the development and testing of Chef recipes intended for use on services
like AWS OpsWorks.

## Installation

1. Install the latest version of [Vagrant](https://www.vagrantup.com/downloads.html)
2. Install the Vagrant DataBags plugin:

```sh
$ vagrant plugin install vagrant-databags
```

## Usage

Example Vagrantfile configuration section for Vagrant DataBags:

```ruby
Vagrant.configure("2") do |config| 
  # Cleanup on provision. 
  # If set, temp data bag folder will be cleaned up upon provision which might be useful if you will inject sensitive data.
  # Defaults to false.
  config.databags.cleanup_on_provision = true

  # Hash of map lambda's per data bag.
  # Each data bag needs a lambda with 2 parameters: items and env and should return the new hash of data bag items
  # Parameter items is a hash of items (per item's id) 
  # Parameter env is vagrant-databags plugin's middleware environment hash with various interesting keys:
  # * env[:ui] is an instance of ::Vagrant::UI::Interface
  # * env[:machine] is an instance of ::Vagrant::Machine etc.
  config.databags.map = {
    :sample_data => lambda { |items, env|
      items['new_data_bag_item_id'] = {
        :name => 'New sample data bag item' 
      } 
      items
    }
  }
end
```

### Usage with other Vagrant plugins

Evaluated data bags are available in other Vagrant plugin's middlewares through `:data_bags` key of the environment hash. 

### More examples

#### Simulate OpsWorks stack

Additional [vagrant-lifecycle](https://github.com/nstojiljkovic/vagrant-lifecycle) plugin is required for this example.

[AWS OpsWorks stacks data bag reference](https://docs.aws.amazon.com/opsworks/latest/userguide/data-bags.html) is 
available on the official AWS documentation website.

Example Vagrantfile configuration section:

```ruby
# Required for $LAST_MATCH_INFO
require 'English'
require 'securerandom'
require 'json'
require 'set'

Vagrant.configure("2") do |config|
  node.databags.cleanup_on_provision = false
  node.databags.map = {
      # Use Lifecycle event as a command
      # @see https://github.com/nstojiljkovic/vagrant-lifecycle 
      # @see https://docs.aws.amazon.com/opsworks/latest/userguide/data-bag-json-command.html
      aws_opsworks_command: lambda {|items, env|
        command_id = SecureRandom.uuid
        command_type = env[:lifecycle_event] || env[:machine].config.lifecycle.default_event.to_s
        items[command_id] = {
            :type => command_type,
            :args => {},
            :sent_at => Time.now.utc.strftime('%FT%T%:z'),
            :command_id => command_id,
            :iam_user_arn => nil,
            :instance_id => env[:machine].name
        }
        items
      },

      # Extract instances from Vagrantfile!
      # @see https://docs.aws.amazon.com/opsworks/latest/userguide/data-bag-json-instance.html
      :aws_opsworks_instance => lambda { |items, env|
        env[:machine].vagrantfile.machine_names.each do |name|

          machine_config = env[:machine].vagrantfile.machine_config(name, nil, nil)
          instance_roles = []
          machine_config[:config].vm.provisioners.each do |chef|
            instance_roles = (chef.config.run_list || []).flat_map {|r|
              case r
              when /^role\[(?<role>.*)\]/
                $LAST_MATCH_INFO['role']
              else
                []
              end
            }
            instance_roles = instance_roles.to_set.to_a
          end

          private_networks = machine_config[:config].vm.networks.select do |network|
            network[0] == :private_network && network[1].key?(:ip)
          end
          public_networks = machine_config[:config].vm.networks.select do |network|
            network[0] == :public_network && network[1].key?(:ip)
          end
          active_machines = env[:machine].env.active_machines.map do |c|
            c[0]
          end

          items[name] = {
              :architecture => "x86_64",
              :auto_scaling_type => nil,
              :availability_zone => "local",
              :ebs_optimized => false,
              :ec2_instance_id => name,
              :elastic_ip => nil,
              :hostname => machine_config[:config].vm.hostname,
              :instance_id => name,
              :instance_type => "custom",
              :layer_ids => instance_roles,
              :os => machine_config[:config].vm.box,
              :private_ip => private_networks.empty? ? nil : private_networks.first[1][:ip],
              :public_ip => public_networks.empty? ? nil : public_networks.first[1][:ip],
              :status => active_machines.include?(name) ? "online" : "stopped",
              :virtualization_type => machine_config[:config].vm.__providers.first,
              :infrastructure_class => "vagrant",
              :role => instance_roles,
              :self => name == env[:machine].name,
          }
        end

        items
      },

      # Use Chef roles as OpsWorks layers
      # @see https://docs.aws.amazon.com/opsworks/latest/userguide/data-bag-json-layer.html
      :aws_opsworks_layer => lambda { |items, env|
        roles = Set.new

        env[:machine].vagrantfile.machine_names.each do |name|
          machine_config = env[:machine].vagrantfile.machine_config(name, nil, nil)

          machine_config[:config].vm.provisioners.each do |chef|
            instance_roles = (chef.config.run_list || []).flat_map {|r|
              case r
              when /^role\[(?<role>.*)\]/
                $LAST_MATCH_INFO['role']
              else
                []
              end
            }
            roles.merge(instance_roles.to_set)
          end
        end

        roles.each do |v|
          items[v] = {
              :layer_id => v,
              :name => v,
              :packages => [],
              :shortname => v,
              :type => "custom",
              :volume_configurations => [],
              :cloud_watch_logs_configuration => {
                  :enabled => false,
                  :log_streams => []
              }
          }
        end
        items
      }
  }
end
```