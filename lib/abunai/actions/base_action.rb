# frozen_string_literal: true

module Abunai
  module Actions
    class BaseAction
      include Abunai::Utils::Common
      attr_reader :router

      def initialize(router, *_args, **_kwargs)
        @router = router
        init_state
      end

      def init_state; end

      def method_missing(method, *args, **kwargs, &block)
        return @router.send(method, *args, **kwargs, &block) if @router.respond_to?(method)

        super
      end

      def respond_to_missing?(method, *args, **kwargs, &block)
        super || @router.respond_to?(method, *args, **kwargs, &block)
      end
    end
  end
end
