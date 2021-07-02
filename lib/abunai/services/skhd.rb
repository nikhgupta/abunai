# frozen_string_literal: true

module Abunai
  module Services
    class Skhd < Base
      def generate
        run_action :GenerateSkhdConfig
      end

      def bindings
        YAML.load_file(File.expand_path(File.join(get_config(:generate_in), "skhdrc.yaml")))
      end

      def installed?
        !`which skhd`.strip.to_s.empty?
      end
    end
  end
end
