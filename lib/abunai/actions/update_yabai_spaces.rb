# frozen_string_literal: true

module Abunai
  module Actions
    class UpdateYabaiSpaces < BaseAction
      include Abunai::Utils::Common

      def run
        update_state

        ensure_spaces
        update_state

        ensure_labels
        update_state

        reorganize_spaces
        remove_unnecessary_spaces
        update_state

        yabai.set_external_bar_height
      end

      private

      def yabai
        @router.yabai
      end

      def state
        yabai.state
      end

      def spaces_count
        get_config :spaces_count
      end

      def current_spaces_count
        state[:spaces].length
      end

      def ensure_spaces
        return if current_spaces_count >= spaces_count

        (spaces_count - current_spaces_count).times { execute "space --create" }
      end

      def ensure_labels
        existing = state[:spaces].map { |space| space["label"] }
        wanted = spaces_count.times.map do |i|
          config.label_for_yabai_space(i)
        end

        (wanted - existing).sort.each.with_index do |label, idx|
          yabai.label_space unlabeled_spaces[idx]["index"], label
        end
      end

      def reorganize_spaces
        current_spaces_count.times do |idx|
          yabai.move_space_to_display idx, config.display_for_yabai_space(idx)["uuid"], uuid: true
        end

        router.load[:yabai][:spaces].each do |space|
          space["windows"].each do |window|
            next unless window_ids.include?(window)

            yabai.move_window_to_space(window, space["label"] == "s" ? "s1" : space["label"])
          end
        end

        # after re-shuffling, focus the "default" spaces
        refocus_first_spaces
      end

      def refocus_first_spaces
        state[:displays].length.times { yabai.focus_space(_1 + 1) }
      end

      def remove_unnecessary_spaces
        return if current_spaces_count <= spaces_count

        unlabeled_spaces.each { run "space #{_1["index"]} --destroy" }
      end
    end
  end
end
