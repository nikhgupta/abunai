# frozen_string_literal: true

module Abunai
  module Services
    class Spacebar < Base
      def generate
        run_action :GenerateSpacebarConfig
      end

      def height
        run "spacebar -m config height"
      end

      def installed?
        !`which spacebar`.strip.to_s.empty?
      end
    end
  end
end
