# frozen_string_literal: true

module Abunai
  module Utils
    module Yabai
      def unlabeled_spaces
        find_all @router.yabai.state[:spaces], "label", ""
      end

      def visible_spaces
        find_all @router.yabai.state[:spaces], "visible", 1
      end

      def focused_space
        find_one @router.yabai.state[:spaces], "focused", 1
      end

      def display_uuids
        @router.yabai.state[:displays].map { _1["uuid"] }
      end

      def window_ids
        @router.yabai.state[:windows].map { _1["id"] }
      end

      def find_display(display: nil, index: nil, uuid: nil)
        return find_one(@router.yabai.state[:displays], "location", display) if display
        return find_one(@router.yabai.state[:displays], "uuid", uuid) if uuid
        return find_one(@router.yabai.state[:displays], "index", index) if index

        raise Abunai::Error, "Must pass one of index, uuid or display to find display"
      end

      def find_space(space: nil, index: nil)
        return find_one(@router.yabai.state[:spaces], "label", @router.config.label_for_yabai_space(space)) if space
        return find_one(@router.yabai.state[:spaces], "index", index) if index

        raise Abunai::Error, "Must pass one of index or space label/number to find space"
      end
    end
  end
end
