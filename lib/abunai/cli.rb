# frozen_string_literal: true

module Abunai
  class CLI < ::Thor
    desc "yabai COMMAND", "run a COMMAND on yabai"
    def yabai(command)
      abunai = Abunai.new
      abunai.yabai.send(command)
    end

    desc "generate NAME", "generate config for [NAME: skhd,spacebar,yabai] service"
    def generate(name)
      abunai = Abunai.new
      usage = abunai.send(name).generate
      puts usage
    end

    desc "highlight VERB [SUBJECT]", "Action to perform when a verb and subject pair modal is activated"
    def highlight(verb, subject = nil)
      abunai = Abunai.new
      abunai.yabai.highlight(verb, subject)
    end
  end
end
