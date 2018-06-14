require 'vagrant/util/hash_with_indifferent_access'

module VagrantPlugins
  module DataBags
    class Config < Vagrant.plugin("2", :config)
      MAYBE = Object.new.freeze

      # Data bags map configuration.
      # @return [Hash]
      attr_accessor :map

      # Data bags map configuration.
      # @return [Boolean]
      attr_accessor :cleanup_on_provision

      def initialize
        super

        @map = Hash.new
        @cleanup_on_provision = false

        @__finalized = false
      end

      def finalize!
        @__finalized = true
      end

      def validate(machine)
        errors = _detected_errors

        if @map.is_a?(Hash)
          @map.each do |k, v|
            if v.respond_to? :call
              unless v.arity == 2
                errors << "#{k} data bag map configuration is expected to be lambda with 2 arguments!"
              end
            else
              errors << "#{k} data bag map configuration is expected to be lambda!"
            end
          end
        else
          errors << "Data bag map configuration is expected to be a hash!"
        end

        {
            "DataBags" => errors
        }
      end

      def to_hash
        raise "Must finalize first." if !@__finalized

        {
            cleanup_on_provision: @cleanup_on_provision,
            map: @map
        }
      end

      def missing?(obj)
        obj.to_s.strip.empty?
      end
    end
  end
end
