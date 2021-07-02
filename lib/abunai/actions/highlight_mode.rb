module Abunai
  module Actions
    class HighlightMode < BaseAction
      def initialize(router, verb, subject)
        super(router)
        @verb = verb
        @subject = subject
        @mode = subject.to_s.strip.empty? ? verb : "#{verb}_#{subject}"
      end

      def run
        return unless get_config(:alfred)
        return unless get_config(:alfred, :cheatsheet)
        return `skhd -k 'escape'` if @mode.to_s == "default"

        bindings = @router.skhd.bindings[@mode.to_s]
        run_alfred(bindings.map { |key, data| "#{format("%-20s", key)}: #{data["help"]}" })
      end

      def run_alfred(arr = [])
        text = arr.join("\n").gsub("\\", "\\\\\\")
        script = "tell application \"Alfred 3\" to run trigger \"#{alfred_trigger}\""
        script = "#{script} in workflow \"#{alfred_workflow}\" with argument \"#{text}\""
        `osascript -e '#{script}' 2>&1`
      end

      def alfred_workflow
        get_config(:alfred, :workflow)
      end

      def alfred_trigger
        get_config(:alfred, :trigger)
      end
    end
  end
end
