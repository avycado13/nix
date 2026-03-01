{
  pkgs,
  config,
  inputs,
  ...
}:
let
  clockScript = pkgs.writeShellScript "clock.sh" ''
    sketchybar --set "$NAME" label="$(date '+%m/%d  %I:%M %p')"
  '';
  wifiScript = pkgs.writeShellScript "wifi.sh" ''
    SSID=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | awk -F': ' '/^ *SSID:/{print $2}')
    RSSI=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | awk -F': ' '/^ *agrCtlRSSI:/{print $2}')
    if [ -z "$SSID" ]; then
      sketchybar --set "$NAME" label="Disconnected" icon="󰤭"
    elif [[ -n "$RSSI" && "$RSSI" -gt -50 ]]; then
      sketchybar --set "$NAME" label="$SSID" icon="󰤨"
    elif [[ -n "$RSSI" && "$RSSI" -gt -70 ]]; then
      sketchybar --set "$NAME" label="$SSID" icon="󰤥"
    else
      sketchybar --set "$NAME" label="$SSID" icon="󰤟"
    fi
  '';
  cpuScript = pkgs.writeShellScript "cpu.sh" ''
    CPU=$(ps -A -o %cpu | awk '{s+=$1} END {printf "%.0f", s}')
    sketchybar --set "$NAME" label="''${CPU}%"
  '';
  ramScript = pkgs.writeShellScript "ram.sh" ''
    MEMORY=$(memory_pressure | grep "System-wide memory free percentage:" | awk '{print 100-$5}')
    sketchybar --set "$NAME" label="''${MEMORY}%"
  '';
  aerospaceScript = pkgs.writeShellScript "aerospace.sh" ''
        if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
        sketchybar --set $NAME background.drawing=on
    else
        sketchybar --set $NAME background.drawing=off
    fi
  '';
  soundScript = pkgs.writeShellScript "sound.sh" ''
    DEVICE=$(SwitchAudioSource -c 2>/dev/null || system_profiler SPAudioDataType 2>/dev/null | awk '/Default Output Device: Yes/{found=1} found && /Device Name:/{print $NF; exit}')
    VOLUME=$(osascript -e 'output volume of (get volume settings)')
    MUTED=$(osascript -e 'output muted of (get volume settings)')
    if [ "$MUTED" = "true" ]; then
      ICON="󰖁"
    elif [ "$VOLUME" -gt 66 ]; then
      ICON="󰕾"
    elif [ "$VOLUME" -gt 33 ]; then
      ICON="󰖀"
    elif [ "$VOLUME" -gt 0 ]; then
      ICON="󰕿"
    else
      ICON="󰖁"
    fi
    sketchybar --set "$NAME" icon="$ICON" label="''${VOLUME}%"
  '';
  nowPlayingScript = pkgs.writeShellScript "now_playing.sh" ''
    PLAYER_STATE=$(osascript -e '
      set output to ""
      if application "Spotify" is running then
        tell application "Spotify"
          if player state is playing then
            set output to (artist of current track) & " - " & (name of current track)
          end if
        end tell
      else if application "Music" is running then
        tell application "Music"
          if player state is playing then
            set output to (artist of current track) & " - " & (name of current track)
          end if
        end tell
      end if
      return output
    ')
    if [ -n "$PLAYER_STATE" ]; then
      if [ ''${#PLAYER_STATE} -gt 40 ]; then
        PLAYER_STATE="$(echo "$PLAYER_STATE" | cut -c1-40)…"
      fi
      sketchybar --set "$NAME" label="$PLAYER_STATE" icon="󰎆" drawing=on
    else
      sketchybar --set "$NAME" drawing=off
    fi
  '';
  dndScript = pkgs.writeShellScript "dnd.sh" ''
    DND=$(defaults read com.apple.controlcenter "NSStatusItem Visible FocusModes" 2>/dev/null)
    FOCUS=$(plutil -extract data.0.modeIdentifier raw ~/Library/DoNotDisturb/DB/Assertions/v2/storeAssertionRecords 2>/dev/null || echo "")
    if [ -n "$FOCUS" ]; then
      sketchybar --set "$NAME" icon="󰍶" icon.color=0xfff38ba8 label="Focus"
    else
      sketchybar --set "$NAME" icon="󰍷" icon.color=0xffa6adc8 label="Off"
    fi
  '';
  heliumScript = pkgs.writeShellScript "helium.sh" ''
    if pgrep -xi "helium" >/dev/null 2>&1 || pgrep -f "Helium.app" >/dev/null 2>&1; then
      sketchybar --set "$NAME" icon.color=0xff89b4fa label="On" label.drawing=on
    else
      sketchybar --set "$NAME" icon.color=0xff6c7086 label="Off" label.drawing=on
    fi
  '';
in
{
  homebrew = {
    enable = true;
    onActivation.autoUpdate = true;

    brews = [
      "openssl"
      "wget"
      "git-crypt"
      "docker"
      "docker-compose"
    ];

    casks = [
      "foks"
      "android-studio"
      "tailscale-app"
      "boring-notch"
      "obsidian"
      "keybase"
      "cloudflare-warp"
      "ghostty"
    ];

    masApps = {
      # Xcode = 497799835;
    };

    taps = builtins.attrNames config.nix-homebrew.taps;
  };

  services.aerospace = {
    enable = true;
    settings = {
      accordion-padding = 30;
      after-startup-command = [ "exec-and-forget sketchybar" ];
      exec-on-workspace-change = [
        "${pkgs.bash}/bin/bash"
        "-c"
        "sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE"
      ];
      automatically-unhide-macos-hidden-apps = false;
      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";

      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;

      gaps = {
        inner = {
          horizontal = 0;
          vertical = 0;
        };
        outer = {
          bottom = 0;
          left = 0;
          right = 0;
          top = 0;
        };
      };

      key-mapping.preset = "qwerty";

      mode = {
        main.binding = {
          alt-1 = "workspace 1";
          alt-2 = "workspace 2";
          alt-3 = "workspace 3";
          alt-4 = "workspace 4";
          alt-5 = "workspace 5";
          alt-6 = "workspace 6";
          alt-7 = "workspace 7";
          alt-8 = "workspace 8";
          alt-9 = "workspace 9";
          alt-a = "workspace A";
          alt-b = "workspace B";
          alt-c = "workspace C";
          alt-comma = "layout accordion horizontal vertical";
          alt-d = "workspace D";
          alt-e = "workspace E";
          alt-equal = "resize smart +50";
          alt-f = "workspace F";
          alt-g = "workspace G";
          alt-h = "focus left";
          alt-i = "workspace I";
          alt-j = "focus down";
          alt-k = "focus up";
          alt-l = "focus right";
          alt-m = "workspace M";
          alt-minus = "resize smart -50";
          alt-n = "workspace N";
          alt-o = "workspace O";
          alt-p = "workspace P";
          alt-q = "workspace Q";
          alt-r = "workspace R";
          alt-s = "workspace S";
          alt-shift-1 = "move-node-to-workspace 1";
          alt-shift-2 = "move-node-to-workspace 2";
          alt-shift-3 = "move-node-to-workspace 3";
          alt-shift-4 = "move-node-to-workspace 4";
          alt-shift-5 = "move-node-to-workspace 5";
          alt-shift-6 = "move-node-to-workspace 6";
          alt-shift-7 = "move-node-to-workspace 7";
          alt-shift-8 = "move-node-to-workspace 8";
          alt-shift-9 = "move-node-to-workspace 9";
          alt-shift-a = "move-node-to-workspace A";
          alt-shift-b = "move-node-to-workspace B";
          alt-shift-c = "move-node-to-workspace C";
          alt-shift-d = "move-node-to-workspace D";
          alt-shift-e = "move-node-to-workspace E";
          alt-shift-g = "move-node-to-workspace G";
          alt-shift-h = "move left";
          alt-shift-i = "move-node-to-workspace I";
          alt-shift-j = "move down";
          alt-shift-k = "move up";
          alt-shift-l = "move right";
          alt-shift-m = "move-node-to-workspace M";
          alt-shift-n = "move-node-to-workspace N";
          alt-shift-o = "move-node-to-workspace O";
          alt-shift-p = "move-node-to-workspace P";
          alt-shift-q = "move-node-to-workspace Q";
          alt-shift-r = "move-node-to-workspace R";
          alt-shift-s = "move-node-to-workspace S";
          alt-shift-semicolon = "mode service";
          alt-shift-t = "move-node-to-workspace T";
          alt-shift-tab = "move-workspace-to-monitor --wrap-around next";
          alt-shift-u = "move-node-to-workspace U";
          alt-shift-v = "move-node-to-workspace V";
          alt-shift-w = "move-node-to-workspace W";
          alt-shift-x = "move-node-to-workspace X";
          alt-shift-y = "move-node-to-workspace Y";
          alt-shift-z = "move-node-to-workspace Z";
          alt-slash = "layout tiles horizontal vertical";
          alt-t = "workspace T";
          alt-tab = "workspace-back-and-forth";
          alt-u = "workspace U";
          alt-v = "workspace V";
          alt-w = "workspace W";
          alt-x = "workspace X";
          alt-y = "workspace Y";
          alt-z = "workspace Z";
          alt-ctrl-tab = "move-workspace-to-monitor --wrap-around next";
        };

        service.binding = {
          alt-shift-h = [
            "join-with left"
            "mode main"
          ];
          alt-shift-j = [
            "join-with down"
            "mode main"
          ];
          alt-shift-k = [
            "join-with up"
            "mode main"
          ];
          alt-shift-l = [
            "join-with right"
            "mode main"
          ];
          backspace = [
            "close-all-windows-but-current"
            "mode main"
          ];
          down = "volume down";
          esc = [
            "reload-config"
            "mode main"
          ];
          f = [
            "layout floating tiling"
            "mode main"
          ];
          r = [
            "flatten-workspace-tree"
            "mode main"
          ];
          shift-down = [
            "volume set 0"
            "mode main"
          ];
          up = "volume up";
        };
      };

      on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

      on-window-detected = [
        {
          "if".app-id = "com.microsoft.VSCode";
          run = "move-node-to-workspace C";
        }
        {
          "if".app-id = "com.tinyspeck.slackmacgap";
          run = "move-node-to-workspace M";
        }
        {
          "if".app-id = "com.apple.MobileSMS";
          run = "move-node-to-workspace M";
        }
      ];
    };
  };
  services.sketchybar = {
    enable = false;
    config = ''
            # This is a demo config to showcase some of the most important commands.
      # It is meant to be changed and configured, as it is intentionally kept sparse.
      # For a (much) more advanced configuration example see my dotfiles:
      # https://github.com/FelixKratz/dotfiles

      PLUGIN_DIR="$CONFIG_DIR/plugins"

      ##### Bar Appearance #####
      # Configuring the general appearance of the bar.
      # These are only some of the options available. For all options see:
      # https://felixkratz.github.io/SketchyBar/config/bar
      # If you are looking for other colors, see the color picker:
      # https://felixkratz.github.io/SketchyBar/config/tricks#color-picker

      sketchybar --bar position=top height=40 blur_radius=30 color=0x40000000

      ##### Changing Defaults #####
      # We now change some default values, which are applied to all further items.
      # For a full list of all available item properties see:
      # https://felixkratz.github.io/SketchyBar/config/items

      default=(
        padding_left=5
        padding_right=5
        icon.font="OpenDyslexic Nerd Font:Bold:17.0"
        label.font="OpenDyslexic Nerd Font:Bold:14.0"
        icon.color=0xffffffff
        label.color=0xffffffff
        icon.padding_left=4
        icon.padding_right=4
        label.padding_left=4
        label.padding_right=4
      )
      sketchybar --default "''${default[@]}"



      ##### Adding Left Items #####
      # We add some regular items to the left side of the bar, where
      # only the properties deviating from the current defaults need to be set

      sketchybar --add event aerospace_workspace_change

      for sid in $(aerospace list-workspaces --focused); do
          sketchybar --add item space.$sid left \
              --subscribe space.$sid aerospace_workspace_change \
              --set space.$sid \
              background.color=0x44ffffff \
              background.corner_radius=5 \
              background.height=20 \
              background.drawing=off \
              label="$sid" \
              click_script="aerospace workspace $sid" \
              script="${aerospaceScript} $sid"
      done

      sketchybar --add item chevron left \
                 --set chevron icon= label.drawing=off \
                 --add item front_app left \
                 --set front_app icon.drawing=off script="$PLUGIN_DIR/front_app.sh" \
                 --subscribe front_app front_app_switched \
                 --add item helium left \
                 --set helium icon="󰖟" update_freq=10 label.drawing=off script="${heliumScript}" \
                 --add item now_playing right \
                 --set now_playing update_freq=5 icon="󰎆" script="${nowPlayingScript}" drawing=off

      ##### Adding Right Items #####
      # In the same way as the left items we can add items to the right side.
      # Additional position (e.g. center) are available, see:
      # https://felixkratz.github.io/SketchyBar/config/items#adding-items-to-sketchybar

      # Some items refresh on a fixed cycle, e.g. the clock runs its script once
      # every 10s. Other items respond to events they subscribe to, e.g. the
      # volume.sh script is only executed once an actual change in system audio
      # volume is registered. More info about the event system can be found here:
      # https://felixkratz.github.io/SketchyBar/config/events

      sketchybar --add item clock right \
                 --set clock update_freq=10 icon=  script="${clockScript}" \
                 --add item volume right \
                 --set volume script="$PLUGIN_DIR/volume.sh" \
                 --subscribe volume volume_change \
                 --add item battery right \
                 --set battery update_freq=120 script="$PLUGIN_DIR/battery.sh" \
                 --subscribe battery system_woke power_source_change \
                 --add item wifi right \
                 --set wifi update_freq=10 icon="󰤨" script="${wifiScript}" \
                 --add item sound right \
                 --set sound update_freq=5 icon="󰕾" script="${soundScript}" \
                 --subscribe sound volume_change \
                 --add item dnd right \
                 --set dnd update_freq=30 icon="󰍷" script="${dndScript}"

      ##### Force all scripts to run the first time (never do this in a script) #####
      sketchybar --update
    '';
    # --add item cpu right \
    #  --set cpu update_freq=5 icon="󰻠" script="${cpuScript}" \
    #  --add item ram right \
    #  --set ram update_freq=10 icon="󰍛" script="${ramScript}" \
  };

  environment.systemPackages = [
    pkgs.colima
    pkgs.coreutils
    pkgs.zstd
    pkgs.duf
    pkgs.ffmpeg
    pkgs.nur.repos.forkprince.helium-nightly
    inputs.nix-auth.packages.aarch64-darwin.default
  ];

  services.virby.enable = false;
  services.virby.onDemand.enable = true;
  services.virby.onDemand.ttl = 10;
  security.pam.services.sudo_local.touchIdAuth = true;

  networking = {
    computerName = "Avyays MacBook Air";
    hostName = "Avys-Mac";
    localHostName = "Avys-Mac";

    dns = [
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];

    knownNetworkServices = [
      "Raspberry Pi Compute Module 4 Rev 1.1"
      "USB 10/100/1000 LAN"
      "Thunderbolt Ethernet"
      "Thunderbolt Bridge"
      "Wi-Fi"
    ];
  };

  system = {
    stateVersion = 5;
    primaryUser = "avy";
  };

  users.users.avy = {
    name = "avy";
    home = "/Users/avy";
    shell = pkgs.zsh;
  };
}
