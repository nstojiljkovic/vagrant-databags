require_relative 'base'
require 'vagrant-databags/data_bags'

module VagrantPlugins
  module DataBags
    module Action
      class DestroyDataBags < Base

        def call(env)
          env[:ui].detail "[vagrant-databags] Destroying temp data bags folder"
          DataBagsContainer.instance.destroy(env[:machine])

          @app.call(env)
        end

      end
    end
  end
end
