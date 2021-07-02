# frozen_string_literal: true

module Abunai
  module Services
    class Base
      include Abunai::Utils::Common
      attr_reader :state

      def initialize(router, *_args, **_kwargs)
        @router = router
        @state = {}
      end

      def update_state; end

      def after_config_parse; end

      def highlight(verb, subject = nil)
        run_action :HighlightMode, verb, subject
      end
    end
  end
end
