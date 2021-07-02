# frozen_string_literal: true

require "yaml"
require "json"
require "open3"
require_relative "abunai/version"
require_relative "abunai/utils"
require_relative "abunai/config"
require_relative "abunai/base"
require_relative "abunai/skhd"
require_relative "abunai/spacebar"
require_relative "abunai/yabai"

module Abunai
  class Error < StandardError; end

  def self.root
    Pathname.new(__FILE__).dirname.dirname
  end

  def self.new(*args, **kwargs, &block)
    Abunai::Base.new(*args, **kwargs, &block)
  end
end
