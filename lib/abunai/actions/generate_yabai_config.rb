# frozen_string_literal: true

module Abunai
  module Actions
    class GenerateYabaiConfig < BaseGenerator
      AVAILABLE_FIELDS = %i[debug layout rules signals].freeze

      def run
        path = Abunai.root.join("templates", "yabairc")
        data = AVAILABLE_FIELDS.map { |f| [f, send(f)] }.to_h
        add_colors_to_data(data)

        generate yabairc: (path.read % data)
        <<~USAGE
          Please, add the following to your `yabairc` configuration:

            source #{@paths["yabairc"]}
        USAGE
      end

      def add_colors_to_data(data)
        get_config(:colors).each do |k, v|
          data[:"colors.#{k}"] = "0x#{format("%8s", v.to_s(16)).gsub(" ", "0")}"
        end
      end

      def debug
        get_config(:yabairc, :debug) ? "on" : "off"
      end

      def layout
        get_config :yabairc, :layout
      end

      def signals
        %w[system_woke display_added display_removed].map do |hook|
          "yabai -m signal --add event=#{hook} action='zsh -c \"abunai yabai update_spaces\"'"
        end.join("\n")
      end

      def rules
        rows = []
        rows << get_config(:apps).map do |rule|
          statement_for(rule)
        end

        get_config(:spaces).each do |name, space|
          rows << space["apps"].map do |rule|
            statement_for(rule, name)
          end
        end

        rows.map { |set| set.join("\n") }.join("\n\n")
      end

      private

      def statement_for(rule, space = nil)
        space = space ? @router.config.id_for_yabai_space(space) : nil
        return "yabai -m rule --add app=\"#{rule}\" space=^#{space}" if rule.is_a?(String)

        command = "yabai -m rule --add app=\"#{rule["match"]}\""
        command = "#{command} title=\"#{rule["title"]}\"" if rule.key?("title")
        command = "#{command} space=#{rule["follow"] == false ? "" : "^"}#{space}" unless space.to_s.strip.empty?
        command = "#{command} manage=#{rule["manage"] ? "on" : "off"}" if rule.key?("manage")
        command = "#{command} border=#{rule["border"] ? "on" : "off"}" if rule.key?("border")
        command = "#{command} sticky=#{rule["sticky"] ? "on" : "off"}" if rule.key?("sticky")

        command
      end
    end
  end
end
