# frozen_string_literal: true

module Abunai
  module Actions
    class BaseGenerator < BaseAction
      def init_state
        @paths = {}
        @config = []
        @gen_state = {}
        @last_comment = nil
      end

      def section(comment)
        with_generator_state(:section) { add_linebreak }
        comment comment
      end

      def chapter(heading)
        with_generator_state(:chapter, close: %i[section]) do
          add_linebreak
          @last_comment = nil
        end

        append("#" * 80)
        comment(heading.upcase)
        append("#" * 80)
      end

      def comment(text)
        return if text.to_s.strip.empty?

        @last_comment = text
        text.scan(/.{1,78}/).each do |line|
          append "# #{line}"
        end
      end

      def append(line)
        @config << line
      end

      protected

      def generate(map)
        path = File.expand_path(get_config(:generate_in))
        FileUtils.mkdir_p(path)

        send :before_generate if respond_to?(:before_generate)
        map.each do |name, data|
          @paths[name.to_s] = File.join(path, name.to_s)
          File.open(@paths[name.to_s], "wb") { |f| f.puts data }
        end
        send :after_generate if respond_to?(:after_generate)
      end

      def hook(method)
        send("before_#{method}") if respond_to?("before_#{method}")
        send(method)
        send("after_#{method}") if respond_to?("after_#{method}")
      end

      private

      def with_generator_state(name, close: [])
        if @gen_state[name]
          yield
          close.each { |r| @gen_state[r] = false }
        else
          @gen_state[name] = true
        end
      end

      def add_linebreak(count = 1)
        count.times { @config << "" }
      end
    end
  end
end
