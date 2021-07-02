module Abunai
  class Base
    include Abunai::Utils
    attr_reader :skhd, :yabai, :spacebar, :config

    def initialize(*args, **kwargs, &block)
      @router = self
      @config = Abunai::Config.new(self)

      @skhd = Abunai::Services::Skhd.new(self, *args, **kwargs, &block)
      @yabai = Abunai::Services::Yabai.new(self, *args, **kwargs, &block)
      @spacebar = Abunai::Services::Spacebar.new(self, *args, **kwargs, &block)

      update_state
    end

    def update_state
      with_services { |_name, service| service.update_state }

      @config.parse! unless @config.resolved?
      raise Abunai::Error, "No display attached??" if display_uuids.length.zero?

      with_services { |_name, service| service.after_config_parse }
      save
    end

    # save current state to cache
    def save
      state = with_services { |name, service| [name, service.state] }.to_h
      File.open(@config.cache, "wb") { |f| f.puts state.to_yaml }
    end

    # load state from cache
    def load
      YAML.load_file(@config.cache)
    end

    private

    def with_services
      %i[yabai skhd spacebar].map do |service|
        yield(service, instance_variable_get("@#{service}"))
      end
    end
  end
end
