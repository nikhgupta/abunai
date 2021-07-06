# frozen_string_literal: true

module Abunai
  module Utils
    module Common
      include Abunai::Utils::Skhd
      include Abunai::Utils::Yabai

      def run_action(name, *args, **kwargs, &block)
        klass = begin
          Abunai::Actions.const_get(name)
        rescue NameError
          raise Abunai::Error, "No such action found: Abunai::Actions::#{name}"
        end

        klass.new(@router, *args, **kwargs, &block).run
      end

      def script_path(*args)
        Pathname.new(config.script_dir).join(*args).to_s
      end

      def get_config(primary, *keys)
        conf = @router.config.send(primary)
        keys.each { |key| conf = conf[key.to_s] }
        conf
      end

      def run(cmd)
        stdout, stderr, status = Open3.capture3(cmd)
        return stdout.strip if status.to_i.zero?

        raise stderr.strip
      end
      alias __run run

      def find_all(objects, key, value)
        objects.map { _1 if _1[key] == value }.compact
      end

      def find_one(objects, key, value)
        objects.each do
          return _1 if _1[key] == value
        end
        nil
      end
    end
  end
end
