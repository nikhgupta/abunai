# frozen_string_literal: true

module Abunai
  module Actions
    class GenerateSpacebarConfig < BaseGenerator
      def init_state
        super
        @active = []
      end

      def run
        append "#!/usr/bin/env sh"

        add_default_config
        add_available_modules

        section "reset highlight when spacebar is loaded"
        append "abunai highlight default"

        generate spacebarrc: @config

        <<~USAGE
          Please, add the following to your `spacebarrc` configuration:

            source "#{@paths["spacebarrc"]}"
        USAGE
      end

      def add_default_config
        add_config layout: {
          position: :top,
          height: 26,
          padding: { left: 20, right: 20 },
          spacing: { left: 25, right: 25 }
        }, _color: {
          background: "0x88282a36",
          foreground: "0x88eff0eb"
        }, _font: {
          text: "Fira Code:Bold:12.0",
          icon: "FiraCode Nerd Font:Regular:14.0"
        }
      end

      def add_available_modules
        add_module(:title)

        add_module(:clock,
                   icon: "",
                   icon_color: "0xff97979B",
                   format: "%d/%m/%y %R")

        add_module(:power,
                   icon_strip: "  ",
                   icon_color: "0xffF3F99D",
                   _battery_icon_color: "0xffFF5c57")

        add_module(:dnd,
                   icon: "",
                   icon_color: "0xff57c7ff")

        add_module(:space,
                   icon: "",
                   icon_strip: "          﫯        ",
                   icon_color: "0xff5af78e")

        add_module(:display, :all,
                   _spaces_for_all_displays: :on,
                   _space_icon_color_secondary: "0xff5AF78E",
                   _space_icon_color_tertiary: "0xff5af78E")

        add_module(:display_separator,
                   icon: "",
                   icon_color: "0xffffffff")
      end

      private

      def add_module(mod, default = :on, **config)
        section "#{mod} configuration"
        add_rule mod.to_sym == :space ? :spaces : mod, default
        config.each do |key, val|
          name = "#{key.to_s[0] == "_" ? "" : "#{mod}_"}#{key.to_s.gsub(/^_/, "")}"
          add_rule name, val
        end
      end

      def add_config(rules = {})
        rules.each do |section, pairs|
          section "#{section.to_s.gsub(/\A_/, "")} configuration"
          pairs.each do |key, val|
            if val.is_a?(Hash)
              val.each do |a, b|
                add_rule "#{key}_#{a}", b
              end
            else
              add_rule "#{key}#{section if section.to_s[0] == "_"}", val
            end
          end
        end
      end

      def add_rule(key, val)
        val = "\"#{val}\"" if val.to_s.split.length > 1 && !key.to_s.include?("strip")
        append "spacebar -m config #{format("%-32s", key)} #{val}"
      end
    end
  end
end
