module Abunai
  class Config
    include Abunai::Utils

    def initialize(router, path: nil)
      @router = router
      @path = path || Abunai.root.join("example.yml")
      @config = YAML.load_file(@path)
      @parsed = false
    end

    def parse!
      find_monitors
      find_primary_monitor
      find_spaces
      @parsed = true
    end

    def resolved?
      @parsed
    end

    def cache
      path = @config.fetch("cache", File.join(ENV["HOME"], ".cache", "abunai"))
      FileUtils.mkdir_p(File.dirname(path))

      path
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

    def display_for_yabai_space(space)
      @config["spaces"][label_for_yabai_space(space)]["on_display"]
    end

    protected

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

    def method_missing(m, *a, **b, &c)
      return @config[m.to_s] if @config.key?(m.to_s)

      super
    end
  end
end
