require 'json'
require 'pathname'

module VagrantPlugins
  module DataBags
    module FileUtil
      def escape_glob_dir(*parts)
        path = ::Pathname.new(::File.join(*parts)).cleanpath.to_s
        path.gsub(/[\\\{\}\[\]\*\?]/) { |x| "\\" + x }
      end

      def find_all_object_dirs(path)
        path = ::File.join(escape_glob_dir(::File.expand_path(path)), "*")
        objects = ::Dir.glob(path)
        objects.delete_if { |o| !::File.directory?(o) }
        objects.map { |o| ::File.basename(o) }
      end

      def find_all_objects(path)
        path = ::File.join(escape_glob_dir(::File.expand_path(path)), "*.json")
        objects = ::Dir.glob(path)
        objects.map { |o| ::File.basename(o) }
      end

      def object_from_json_file(filename)
        r = ::JSON.parse(IO.read(filename))
        unless r.key?('id')
          r['id'] = ::File.basename(filename, ".*")
        end
        r
      end
    end
  end
end
