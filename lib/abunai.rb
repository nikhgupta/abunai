# frozen_string_literal: true

require "pry"
require "yaml"
require "json"
require "open3"
require "fileutils"
require "digest/md5"

require_relative "abunai/version"
require_relative "abunai/utils/yabai"
require_relative "abunai/utils/skhd"
require_relative "abunai/utils/common"

require_relative "abunai/config"
require_relative "abunai/base"

require_relative "abunai/services/base"
require_relative "abunai/services/skhd"
require_relative "abunai/services/spacebar"
require_relative "abunai/services/yabai"

require_relative "abunai/actions/base_action"
require_relative "abunai/actions/base_generator"
require_relative "abunai/actions/highlight_mode"
require_relative "abunai/actions/update_yabai_spaces"
require_relative "abunai/actions/generate_skhd_config"
require_relative "abunai/actions/generate_yabai_config"
require_relative "abunai/actions/generate_spacebar_config"

module Abunai
  class Error < StandardError; end

  def self.root
    Pathname.new(__FILE__).dirname.dirname
  end

  def self.new(*args, **kwargs, &block)
    Abunai::Base.new(*args, **kwargs, &block)
  end
end
