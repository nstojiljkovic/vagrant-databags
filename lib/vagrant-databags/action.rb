require "pathname"

module VagrantPlugins
  module DataBags
    module Action
      # The autoload farm
      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :CleanDataBags, action_root.join("clean_databags")
      autoload :DestroyDataBags, action_root.join("destroy_databags")
      autoload :LoadDataBags, action_root.join("load_databags")
      autoload :PersistDataBags, action_root.join("persist_databags")
    end
  end
end