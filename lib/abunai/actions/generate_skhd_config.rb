# frozen_string_literal: true

module Abunai
  module Actions
    class GenerateSkhdConfig < BaseGenerator
      def init_state
        super
        @keys = {}
        @modes = []
        @_cache = {}
      end

      def run
        hook :add_modals
        hook :add_bindings_for_modal_switch
        hook :add_keybindings_for_focus
        hook :add_keybindings_for_move
        hook :add_keybindings_for_swap
        hook :add_keybindings_for_space_rotation
        hook :add_keybindings_for_grid
        hook :add_keybindings_for_resize
        hook :add_keybindings_for_toggle
        hook :add_keybindings_for_launch
        hook :add_keybindings_with_fn_key

        generate skhdrc: @config, "skhdrc.yaml": @keys.to_yaml

        <<~USAGE
          Please, add the following to your `skhdrc` configuration:

            .load "#{@paths["skhdrc"]}"
        USAGE
      end

      def add_keybindings_for_launch
        chapter "launch bindings"
        hook :add_keybindings_for_app_launch
        hook :add_keybindings_for_finder_windows
        hook :add_keybindings_for_toggle_scripts
        hook :add_keybindings_for_terminal_launch
        hook :add_keybindings_for_restarting_services
        hook :add_keybindings_for_custom_script_launch
      end

      def add_keybindings_with_fn_key
        chapter "global fn bindings"
        section "open quick apps"
        add_remap :c, :launch_app
        add_remap :e, :launch_app
        add_remap :f, :launch_finder, :d
        add_remap :t, :launch_script
        add_remap :return, :launch_script, :t, modifier: "cmd"

        section "quickly maximize a window or change its layout"
        add_remap :o, :resize, :m
        add_remap :b, :toggle_space
        add_remap :s, :toggle_space

        section "focus windows quickly"
        add_direction_remap :focus_window

        section "focus spaces quickly"
        add_numeric_remap :focus_space

        section "focus displays quickly"
        add_numeric_remap :focus_display, extra_modifier: :cmd, except: (4..10)

        section "swap windows quickly"
        add_direction_remap :swap_window, extra_modifier: :shift

        section "move a window to given space and focus that space"
        add_numeric_remap :move_window, extra_modifier: :shift

        section "move a window to given display and focus that display"
        add_numeric_remap :move_window, extra_modifier: %i[cmd shift], except: (4..10)
      end

      def add_modals
        chapter "vim-like modal behaviour"
        section "defaut mode - return with HYPER or ESC"
        add_modal_definition :default

        section "listening for hotkeys - activate with HYPER"
        add_modal_definition :active

        get_config(:binding_verbs).each_value do |verb|
          if verb[:subjects].any?
            section "#{verb[:name]} a given #{verb[:subjects].keys.join(", ")}"
          else
            section "activate #{verb[:name]} related keybindings"
          end
          add_modal_definition(verb[:name])
          verb[:subjects].each_value do |sub|
            add_modal_definition(verb[:name], sub[:name])
          end
        end
      end

      def add_bindings_for_modal_switch
        chapter "modal activation/deactivation"
        section "activate/deactivate keybindings hyperchord"
        add_modal_binding :default, hyper, :active
        add_modal_binding :active, hyper, :default
        add_modal_binding :active, :escape, :default

        get_config(:binding_verbs).each_value do |verb|
          section "#{verb[:name]} mode"
          add_modal_binding :active, verb[:key], verb[:name]

          modes = []
          verb[:subjects].each_value do |sub|
            modes << "#{verb[:name]}_#{sub[:name]}"
            add_modal_binding verb[:name], sub[:key], modes.last
          end

          modes = [verb[:name], modes].flatten.uniq
          add_modal_binding(*modes, hyper, :default)
          add_modal_binding(*modes, :escape, :default)
        end
      end

      def add_keybindings_for_focus
        chapter "focus keybindings"

        section "focus a window within current space"
        add_directional_bindings :focus_window, "window --focus %<id>s", help: "focus on window %<dir>s"

        section "focus a space within current display"
        add_common_bindings :focus_space, "space --focus %<id>s", help: "focus on space %<dir>s"

        section "focus a particular display"
        add_common_bindings :focus_display, "display --focus %<id>s", help: "focus on display %<dir>s"
      end

      def add_keybindings_for_move
        chapter "move keybindings"

        section "move a window within current space"
        add_directional_bindings :move_window,
                                 "window --warp %<id>s", except: %w[prev1 next1],
                                                         help: "move to window %<dir>s"

        section "move a window to another space and focus that space"
        add_numeric_bindings :move_window,
                             "window --space %<id>s", "space --focus %<id>s",
                             help: "move window to space %<dir>s and focus that space"

        section "move a window to another space and focus that space (using shift key)"
        add_common_bindings :move_window,
                            "window --space %<id>s", "space --focus %<id>s",
                            modifier: :shift,
                            help: "move window to space %<dir>s and focus that space"

        section "move a window to another display and focus that display"
        add_common_bindings :move_window,
                            "window --display %<id>s", "display --focus %<id>s",
                            modifier: :cmd,
                            help: "move window to display %<dir>s and focus that display"

        section "move a space within current display"
        add_common_bindings :move_space,
                            "m space --move %<id>s",
                            help: "move to space %<dir>s within current display"

        section "move a space to another display and focus that display"
        add_common_bindings :move_space,
                            "space --display %<id>s", "display --focus %<id>s",
                            modifier: :shift,
                            help: "move space to display %<dir>s and focus that display"
      end

      def add_keybindings_for_swap
        chapter "swap keybindings"

        section "swap a window within current space"
        add_directional_bindings :swap_window,
                                 "window --swap %<id>s", except: %w[prev1 next1],
                                                         help: "swap window with window %<dir>s"

        section "swap a window from another space and focus that space"
        add_numeric_bindings :swap_window,
                             "window --space %<id>s", "space --focus %<id>s",
                             help: "swap window to space %<dir>s and focus that space"

        section "swap a window from another space and focus that space (using shift key)"
        add_common_bindings :swap_window,
                            "window --space %<id>s", "space --focus %<id>s",
                            modifier: :shift,
                            help: "swap window to space %<dir>s and focus that space"

        section "swap a space within current display"
        add_common_bindings :swap_space, "space --swap %<id>s", help: "swap space with space %<dir>s"

        section "swap a space from another display and focus that display"
        add_common_bindings :swap_space,
                            "space --display %<id>s", "display --focus %<id>s",
                            modifier: :shift,
                            help: "swap space to display %<dir>s and focus that display"
      end

      def add_keybindings_for_space_rotation
        section "rotate/flip windows within current space"
        add_yabai_binding %i[move_window swap_window], "x", "space --mirror x-axis",
                          help: "flip windows in current space along x-axis"
        add_yabai_binding %i[move_window swap_window], "y", "space --mirror y-axis",
                          help: "flip windows in current space along y-axis"
        add_yabai_binding %i[move_window swap_window], "0x2F", "space --rotate 90",
                          help: "rotate windows in current space clockwise"
        add_yabai_binding %i[move_window swap_window], "0x2B", "space --rotate 270",
                          help: "rotate windows in current space anti-clockwise"
      end

      def add_keybindings_for_grid
        keys = get_config(:bindings, :grids)

        chapter "grid keybindings"
        section "window occupies specific part of screen on current space (default: maximized)"
        add_yabai_binding %i[grid grid_window], :m, "window --grid #{keys["m"]}", help: "maximize the current window"

        section "window occupies specific part of screen on current space (default: 1/2)"
        add_yabai_binding %i[grid grid_window], :h, "window --grid #{keys["h"]}",
                          help: "resize window to occupy left-half of screen"
        add_yabai_binding %i[grid grid_window], :j, "window --grid #{keys["j"]}",
                          help: "resize window to occupy bottom-half of screen"
        add_yabai_binding %i[grid grid_window], :k, "window --grid #{keys["k"]}",
                          help: "resize window to occupy top-half of screen"
        add_yabai_binding %i[grid grid_window], :l, "window --grid #{keys["l"]}",
                          help: "resize window to occupy right-half of screen"

        section "window occupies specific part of screen on current space (default: 1/4)"
        add_yabai_binding %i[grid grid_window], :h,
                          "window --grid #{keys["with_alt"]["h"]}",
                          modifier: :alt, help: "resize window to occupy top-left of screen"
        add_yabai_binding %i[grid grid_window], :j,
                          "window --grid #{keys["with_alt"]["j"]}",
                          modifier: :alt, help: "resize window to occupy bottom-left of screen"
        add_yabai_binding %i[grid grid_window], :k,
                          "window --grid #{keys["with_alt"]["k"]}",
                          modifier: :alt, help: "resize window to occupy top-right of screen"
        add_yabai_binding %i[grid grid_window], :l,
                          "window --grid #{keys["with_alt"]["l"]}",
                          modifier: :alt, help: "resize window to occupy bottom-right of screen"
      end

      def add_keybindings_for_resize
        map = { h: [:left, -20, 0], j: [:bottom, 0, 20], k: [:top, 0, -20], l: [:right, 20, 0] }
        chapter "resize keybinding"
        section "NOTE: we do not exit this mode automatically"
        section "Rebalance all windows in current space to be of equal size (if layout allows)"
        add_yabai_binding %i[resize resize_window], equal_key, "space --balance",
                          help: "rebalanace all windows in current space to be of equal size"

        section "maximize and recenter a window quickly"
        add_yabai_binding %i[resize resize_window], :m, "window --toggle zoom-fullscreen", "window --grid 1:1:0:0:1:1",
                          help: "maximize current window"
        add_yabai_binding %i[resize resize_window], :c, "window --toggle float", "window --grid 4:4:1:1:2:2",
                          help: "recenter current window on exact half of the screen"

        section "resize a window incrementally"
        map.each do |key, row|
          add_yabai_binding %i[resize resize_window], key,
                            "window --resize #{row.join(":")}",
                            escape: nil,
                            help: "resize window by an increment in #{row[0]} direction"
        end

        section "reverse resize a window incrementally"
        map.each do |key, row|
          add_yabai_binding %i[resize resize_window], key,
                            "window --resize #{row[0]}:#{-row[1]}:#{-row[2]}",
                            modifier: :alt, escape: nil,
                            help: "resize window by an increment in reverse #{row[0]} direction"
        end
      end

      def add_keybindings_for_toggle
        chapter "toggle keybindings"
        section "toggle current window properties"
        add_toggle_binding :window, :f, "float"
        add_toggle_binding :window, :s, "sticky"
        add_toggle_binding :window, :t, "topmost"
        add_toggle_binding :window, :b, "border"
        add_toggle_binding :window, :i, "split"
        add_toggle_binding :window, :p, "pip"
        add_toggle_binding :window, :z, "zoom-parent"
        add_toggle_binding :window, :m, "zoom-fullscreen"

        section "toggle native fullscreen for current window"
        add_toggle_binding :window, :m, "native-fullscreen", modifier: :shift

        section "float a window and recenter it to occupy exact half on screen"
        add_toggle_binding :window, :c, "float", "--grid 4:4:1:1:2:2"

        section "toggle or apply space related properties"
        add_toggle_binding :space, :d, "show-desktop"
        add_toggle_binding :space, :o, "padding", "--toggle gap", help: "toggle padding and gap in current space"
        add_toggle_binding :space, :b, "--layout bsp", prefix: false, help: "use bsp layout in current space"
        add_toggle_binding :space, :f, "--layout float", prefix: false, help: "use float layout in current space"
        add_toggle_binding :space, :s, "--layout stack", prefix: false, help: "use stack layout in current space"
        add_toggle_binding :space, equal_key, "--balance", prefix: false, help: "rebalance windows in current space"
      end

      def add_keybindings_for_terminal_launch
        section "open a new terminal window"
        add_launch_binding :script, :t, script_path("new-terminal.applescript")

        comment "open current finder window in new terminal"
        add_launch_binding :script, :f, script_path("new-terminal.applescript finder")
      end

      def add_keybindings_for_app_launch
        apps = { c: "Google Chrome", m: "Mail", a: "Script Editor", e: "Visual Studio Code" }

        section "launch apps"
        apps.each { |key, app| add_launch_binding :app, key, "open -a '#{app}'", help: "open application: #{app}" }
      end

      def add_keybindings_for_restarting_services
        section "restart services quickly"
        map = { s: :spacebar, k: :skhd, y: :yabai, r: %i[skhd yabai] }
        map.each do |key, servs|
          servs = [servs].flatten
          name = servs.join(" and ")

          cmd = servs.map { |serv| "brew services restart #{serv}" }.join("; ")
          cmd = "terminal-notifier -message 'restarting #{name}' -title skhd -sender com.koekeishiya.skhd; #{cmd}"
          add_launch_binding :restart, key, cmd, help: "restart #{name}"
        end
      end

      def add_keybindings_for_toggle_scripts
        section "quick toggle OS features"
        comment "toggle dock autohide"
        script = "osascript -e 'tell application \"System Events\" to set autohide of dock preferences to not (get autohide of dock preferences)'"
        add_launch_binding :script, :d, script

        comment "toggle hidden files in Finder"
        script = "osascript -e 'tell application \"System Events\" to keystroke \".\" using {command down, shift down}'"
        add_launch_binding :script, :h, script

        comment "toggle dark mode"
        script = "osascript -e 'tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode'"
        add_launch_binding :script, :n, script
      end

      def add_keybindings_for_finder_windows
        section "launch finder windows"
        add_launch_binding :finder, :h, "open ~", help: "open HOME in a finder window"
        dirs = { a: "Applications", d: "Downloads", m: "Music", p: "Pictures", s: "Pictures/Screenshots" }
        dirs.each do |key, dir|
          add_launch_binding :finder, key, "open ~/#{dir}", help: "open #{dir} in a finder window"
        end
        add_launch_binding :finder, :a, "open /Applications", modifier: :shift,
                                                              help: "open /Applications in a finder window"
      end

      def add_keybindings_for_custom_script_launch
        section "launch custom scripts with numeric keybindings"
        comment "NOTE: You should make scripts executable for them to run."
        10.times do |i|
          path = script_path("hotkey-#{i}")
          add_launch_binding :script, i, path, help: "launch script: #{path}"
        end
      end

      protected

      def log_key(key, mode, help, command, **_options)
        @keys[mode] ||= {}
        @keys[mode][key] = { "help" => help, "command" => command.to_s.gsub(/\s+/, " ") }
      end

      def add_modal_definition(verb, subject = nil)
        name = subject ? "#{verb}_#{subject}" : verb
        @modes << name.to_sym
        command = "abunai highlight #{verb}#{" #{subject}" if subject}"
        append ":: #{format("%-16s", name)} #{verb == :default ? " " : "@"} : #{command}"
      end

      def add_modal_binding(*modes, key, switch_to, **options)
        help = "activate #{switch_to} mode"
        if key == hyper && switch_to.to_sym == :active
          help = "start listening for keybindings (active mode)"
        elsif key == hyper || key == :escape
          help = "return to normal/default mode"
        end
        add_binding(*modes, key, switch_to, escape: nil, help: help, modal: true, **options)
      end

      def add_direction_remap(mode, target_key: nil, only: [], except: [], **options)
        get_config(:binding_directions).each do |key, row|
          next if %w[prev1 next1 recent1].include?(row["real_direction"])
          next if row["secondary"] || except.include?(row["direction"]) || except.include?(row["real_direction"])
          next if only.any? && !only.include?(row["direction"])

          add_remap key, mode, target_key || row["real"], **options
        end
      end

      def add_numeric_remap(mode, except: [], **options)
        10.times do |i|
          next if except.include?(i + 1)

          key = ((i + 1) % 10).to_s
          add_remap key, mode, nil, **options
        end
        add_remap :prev1, :focus_space, nil, **options
        add_remap :next1, :focus_space, nil, **options
        add_remap :recent1, :focus_space, nil, **options
      end

      def add_remap(key, mode, target_key = nil, modifier: :fn, **options)
        target = target_key || key
        target = options[:command_modifier] ? "#{options[:command_modifier]} - #{target}" : target
        modifier = options[:extra_modifier] ? "#{modifier} + #{[options[:extra_modifier]].flatten.join(" + ")}" : modifier
        command = (@keys[mode.to_s] || {})[target.to_s]["command"]
        add_binding(nil, key, command, modifier: modifier, escape: nil, **options)
      rescue StandardError
        rows = get_config(:binding_directions).select do |_, r|
          r["direction"] == key.to_s || r["real_direction"] == key.to_s
        end

        options.delete :extra_modifier
        rows.each { |(_k, r)| add_remap(r["keycode"], mode, target_key || r["real"], modifier: modifier, **options) }
      end

      def add_toggle_binding(target, key, *commands, prefix: true, **options)
        options[:help] ||= "toggle #{commands[0]} in current #{target}"
        command = prefix ? "--toggle #{commands.shift}" : commands.shift
        command = "yabai -m #{target} #{command}"
        remaining = commands.map { |c| "yabai -m #{target} #{c}" }.join("; ")
        command = "#{command}; #{remaining}" if commands.any?

        add_binding "toggle_#{target}", key, command, **options
      end

      def add_launch_binding(target, key, *commands, **options)
        options = options.merge(escape: :prefix)
        add_binding "launch_#{target}", key, commands.join("; "), **options
      end

      def add_directional_bindings(modes, *commands, help: nil, except: [], **options)
        get_config(:binding_directions).each do |key, row|
          next if row["secondary"]
          next if except.include?(row["direction"]) || except.include?(row["real_direction"])

          help_text = format(help.to_s, dir: row["direction"])
          current = commands.map { |cmd| format(cmd, id: format("%-7s", row["direction"])) }
          add_yabai_binding(modes, key, *current, help: help_text, **options)
        end
      end

      def add_numeric_bindings(modes, *commands, help: nil, **options)
        10.times do |key|
          help_text = format(help.to_s, dir: key + 1)
          current = commands.map { |cmd| format(cmd, id: format("%-7s", key + 1)) }
          add_yabai_binding(modes, (key + 1) % 10, *current, help: help_text, **options)
        end
      end

      def add_common_bindings(*modes, command, **options)
        add_directional_bindings(*modes, command, **options)
        add_numeric_bindings(*modes, command, **options)
      end

      def add_yabai_binding(modes, key, *commands, **options)
        commands = commands.map { |cmd| "yabai -m #{cmd}" }.join("; ")
        add_binding(*[modes].flatten, key, commands, **options)
      end

      def add_binding(*modes, key, command, escape: :suffix, **options)
        modes = modes.compact.any? ? modes.map(&:to_sym) & @modes : []
        modifier = options.fetch(:modifier, nil)
        row = get_config(:binding_directions, key)
        key = _format_key_with_modifier(key, modifier)
        real_key = row ? _format_key_with_modifier(row["real"], modifier) : key
        options[:comment] ||= "key: #{real_key}" if real_key != key
        modes.each do |mode|
          log_cmd = options[:modal] ? "" : command
          log_key real_key.strip, mode.to_s, options.fetch(:help, @last_comment), log_cmd
        end
        command = _add_escape_press(command, escape: escape)
        command = "#{key} #{options.fetch(:modal, false) ? ";" : ":"} #{command}"
        str = modes.any? ? "#{format("%-6s", modes.join(", "))} < #{command}" : command
        append(options[:comment] ? "#{str} # #{options[:comment]}" : str)
      end

      private

      def _add_escape_press(command, escape: :suffix)
        return command if escape.nil?

        esc = "skhd -k 'escape'"
        escape == :prefix ? "#{esc}; #{command}" : "#{command}; #{esc}"
      end

      def _format_key_with_modifier(key, modifier, with = 12, without = 4)
        format("%-#{modifier ? with : without}s", modifier ? "#{modifier} - #{key}" : key)
      end
    end
  end
end
