# frozen_string_literal: true

module Abunai
  module Utils
    module Skhd
      def to_keycode(key)
        get_config(:bindings, :directions, key, :code)
      end

      def hyper
        get_config :skhdrc, :hyper_key
      end

      def equal_key
        found = get_config(:binding_directions).detect { |_, r| r["direction"] == "equalize" }
        found ? found[1]["keycode"] : "0x18"
      end
    end
  end
end
