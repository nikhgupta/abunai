# frozen_string_literal: true

module Abunai
  class Config
    include Abunai::Utils::Common

    def initialize(router, path: nil)
      @router = router
      @path = path || Abunai.root.join("templates", "config.yml")
      @config = YAML.load_file(@path)
      @parsed = false
    end

    def parse!
      return if resolved?

      if File.exist?(config_cache)
        @config = YAML.load_file(config_cache)
      else
        find_monitors
        find_primary_monitor
        find_spaces
        find_bindings

        File.open(config_cache, "wb") { |f| f.puts @config.to_yaml }
      end

      @parsed = true
    end

    def resolved?
      @parsed
    end

    def cache
      path = Pathname.new(get_config(:generate_in)).expand_path
      path = path.join(".cache", "abunai.yaml")
      FileUtils.mkdir_p(path.dirname) unless path.dirname.directory?

      path.to_s
    end

    def config_cache
      return @config_cache_path if @config_cache_path

      hash = Digest::MD5.hexdigest(@config.to_yaml)
      path = Pathname.new(get_config(:generate_in)).expand_path
      path = path.join(".cache", "config-#{hash}.yaml")
      FileUtils.mkdir_p(path.dirname) unless path.dirname.directory?

      @config_cache_path = path.to_s
    end

    def available_monitors
      @config["monitors"].select { |monitor| monitor["found"] }
    end

    def space_names
      @config["spaces"].keys
    end

    def spaces_count
      @config["spaces"].length
    end

    def label_for_yabai_space(space)
      return space if space_names.include?(space)
      return space_names[space] if (0..spaces_count - 1).include?(space)

      message = "space must be a string in (#{space_names.join(", ")})"
      message = "#{message} or an integer between 0 and #{space_names.length - 1}"
      raise Abunai::Error, message
    end

    def id_for_yabai_space(space)
      space = label_for_yabai_space(space)
      space_names.each.with_index do |sn, i|
        return i + 1 if space == sn
      end
    end

    def display_for_yabai_space(space)
      @config["spaces"][label_for_yabai_space(space)]["on_display"]
    end

    protected

    def find_bindings
      @config["binding_subjects"] = @config["bindings"]["subjects"].map do |subject|
        key = subject.scan(/_(.)_/)[0][0]
        name = subject.gsub("_", "")
        [name, { key: key, name: name }]
      end.to_h

      @config["binding_verbs"] = @config["bindings"]["verbs"].map do |verb, subs|
        name = verb.gsub("_", "")
        key = verb.scan(/_(.)_/)[0][0]
        data = subs.to_s.chars.map do |char|
          @config["binding_subjects"].detect { |_k, v| v[:key] == char }
        end
        [name, { key: key, name: name, subjects: data.to_h }]
      end.to_h

      @config["binding_directions"] = @config["bindings"]["directions"].map do |key, item|
        item = { "direction" => item, "keycode" => key } if item.is_a?(String)
        item = item.merge("real" => key, "real_direction" => item["direction"])
        item["direction"] = item["direction"].gsub(/\d+$/, "")
        item["keycode"] = "0x#{item["keycode"].to_s(16).upcase}" if item["keycode"].is_a?(Numeric)
        [item["keycode"], item]
      end.to_h
    end

    def find_monitors
      @config["monitors"] = @config["monitors"].map do |monitor|
        data = monitor.merge("found" => display_uuids.include?(monitor["uuid"]))
        [monitor["name"], data]
      end.to_h
    end

    def find_primary_monitor
      @config["primary_monitor"] = @config["monitors"].values.min_by do |monitor|
        monitor["priority"].to_i
      end
    end

    def find_spaces
      @config["spaces"] = @config["spaces"].map do |space|
        data = space.reject { |k, _v| k == "name" }
        data["displays"] ||= [@config["primary_monitor"]["name"]]
        data["displays"] = data["displays"].map { |name| @config["monitors"][name] }
        data["on_display"] = data["displays"].map { |item| item if item["found"] }.compact.first

        [space["name"], data]
      end.to_h
    end

    def method_missing(method, *args, **kwargs, &block)
      return @config[method.to_s] if @config.key?(method.to_s)

      super
    end

    def respond_to_missing?(method, *args, **kwargs, &block)
      super || @config.key?(method.to_s)
    end
  end
end
