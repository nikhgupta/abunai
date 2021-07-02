# frozen_string_literal: true

module Abunai
  module Services
    class Yabai < Base
      IGNORED_ERRORS = [
        "acting space is already located on the given display.",
        "cannot focus an already focused space."
      ].freeze
      # # TODO: need to handle following errors:
      # "acting space is the last user-space on the source display and cannot be destroyed."
      # "acting space is the last user-space on the source display and cannot be moved."

      def initialize(*args, **kwargs)
        super
        @state = { displays: [], spaces: [], windows: [] }
      end

      def update_state
        @local_config = {}
        @state = @state.map { |k, _v| [k, query(k)] }.to_h
      end

      def after_config_parse
        @router.config.monitors.each do |_name, monitor|
          display = find_display(uuid: monitor["uuid"])
          next unless display

          display["location"] = monitor["index"]
        end
      end

      # command: label a given space
      def label_space(space_index, label)
        execute "space #{space_index} --label #{name_for(label)}"
      end

      # command: focus on a given space
      def focus_space(space)
        execute "space --focus #{id_for(space)}"
      end

      # command: move window to a given space
      def move_window_to_space(window, space)
        execute "window #{window} --space #{id_for(space)}"
      end

      # command: move space to a given display
      def move_space_to_display(space, display, uuid: false)
        opts = uuid ? { uuid: display } : { display: display }
        display_index = find_display(**opts)["index"]
        execute "space #{id_for(space)} --display #{display_index}"
      end

      # command: move focus but allow moving across displays when using east or west.
      def focus_window(direction)
        execute "window --focus #{direction}"
      rescue StandardError => e
        raise unless e.message.include?("could not locate a #{direction}ward managed window.")

        execute "display --focus #{direction}"
      end

      # Command: swap 1st and 2nd spaces of on all displays
      def swap_context
        @state[:displays].length.times do |idx|
          first = find_space(idx)
          second = find_space(idx + displays.length)

          label_space(first["index"], i + displays.length)
          label_space(second["index"], i)
        end
        refocus_first_spaces
      end

      # command: update spaces to be consistent
      def update_spaces
        run_action :UpdateYabaiSpaces
      end

      def set_external_bar_height
        return unless @router.spacebar.installed?

        height = @router.spacebar.height
        execute "config external_bar all:#{height}:0"
      end

      def generate
        run_action :GenerateYabaiConfig
      end

      protected

      def name_for(space)
        @router.config.label_for_yabai_space(space)
      end

      def id_for(space)
        @router.config.id_for_yabai_space(space)
      end

      def query(domain)
        res = execute "query --#{domain}"
        res ? JSON.parse(res) : {}
      end

      def installed?
        !`which yabai`.strip.to_s.empty?
      end

      private

      def execute(cmd)
        run "#{`which yabai`.strip} -m #{cmd}"
      rescue StandardError => e
        if IGNORED_ERRORS.include?(e.message)
          puts "While running `yabai -m #{cmd}`, we received error: #{e.message}"
        else
          puts cmd if e.message.include?("value 's' is not")
          raise
        end
      end
    end
  end
end
