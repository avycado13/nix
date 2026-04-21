{ pkgs, ... }:

let
  clockScript = pkgs.writeShellScript "clock.sh" ''
    sketchybar --set "$NAME" label="$(date '+%a %d %b  %I:%M %p')"
  '';

  wifiScript = pkgs.writeShellScript "wifi.sh" ''
    INFO=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I)

    SSID=$(echo "$INFO" | awk -F': ' '/ SSID/{print $2}')
    RSSI=$(echo "$INFO" | awk -F': ' '/agrCtlRSSI/{print $2}')

    if [ -z "$SSID" ]; then
      ICON="󰤭"
      LABEL="Disconnected"
    elif [ "$RSSI" -gt -50 ]; then
      ICON="󰤨"
      LABEL="$SSID"
    elif [ "$RSSI" -gt -70 ]; then
      ICON="󰤥"
      LABEL="$SSID"
    else
      ICON="󰤟"
      LABEL="$SSID"
    fi

    sketchybar --set "$NAME" icon="$ICON" label="$LABEL"
  '';

  volumeScript = pkgs.writeShellScript "volume.sh" ''
    VOL=$(osascript -e 'output volume of (get volume settings)')
    MUTED=$(osascript -e 'output muted of (get volume settings)')

    if [ "$MUTED" = "true" ]; then
      ICON="󰖁"
    elif [ "$VOL" -gt 66 ]; then
      ICON="󰕾"
    elif [ "$VOL" -gt 33 ]; then
      ICON="󰖀"
    elif [ "$VOL" -gt 0 ]; then
      ICON="󰕿"
    else
      ICON="󰖁"
    fi

    sketchybar --set "$NAME" icon="$ICON" label="$VOL%"
  '';

  heliumScript = pkgs.writeShellScript "helium.sh" ''
    if pgrep -x "Helium" >/dev/null; then
      sketchybar --set "$NAME" icon.color=0xff89b4fa label="On"
    else
      sketchybar --set "$NAME" icon.color=0xff6c7086 label="Off"
    fi
  '';

  # FIX: workspaceIndicatorScript is now actually wired up and used below
  workspaceIndicatorScript = pkgs.writeShellScript "workspace_indicator.sh" ''
    WINDOWS=$(aerospace list-windows --workspace "$1" | wc -l | tr -d ' ')

    if [ "$WINDOWS" -gt 0 ]; then
      sketchybar --set "$NAME" icon="●"
    else
      sketchybar --set "$NAME" icon="○"
    fi
  '';

  cpuScript = pkgs.writeShellScript "cpu.sh" ''
    CPU=$(top -l 1 | awk '/CPU usage/ {print int($3 + $5)}')
    sketchybar --set "$NAME" label="$CPU%"
  '';

  batteryScript = pkgs.writeShellScript "battery.sh" ''
    INFO=$(pmset -g batt)
    PERCENT=$(echo "$INFO" | grep -Eo "[0-9]+%" | head -1 | tr -d %)

    if [ "$PERCENT" -gt 80 ]; then
      ICON="󰁹"
    elif [ "$PERCENT" -gt 60 ]; then
      ICON="󰂀"
    elif [ "$PERCENT" -gt 40 ]; then
      ICON="󰁿"
    elif [ "$PERCENT" -gt 20 ]; then
      ICON="󰁾"
    else
      ICON="󰁺"
    fi

    sketchybar --set "$NAME" icon="$ICON" label="$PERCENT%"
  '';

  # FIX: Corrected Nix escape syntax: ''${VAR} instead of \${VAR}
  # FIX: Fixed icon to use a network speed icon instead of wifi icon
  wifiSpeedScript = pkgs.writeShellScript "wifi_speed.sh" ''
    IFACE=$(route get default | awk '/interface/ {print $2}')

    RX1=$(netstat -ibn | awk -v iface="$IFACE" '$1 == iface {print $7; exit}')
    TX1=$(netstat -ibn | awk -v iface="$IFACE" '$1 == iface {print $10; exit}')

    sleep 1

    RX2=$(netstat -ibn | awk -v iface="$IFACE" '$1 == iface {print $7; exit}')
    TX2=$(netstat -ibn | awk -v iface="$IFACE" '$1 == iface {print $10; exit}')

    RX=$((RX2 - RX1))
    TX=$((TX2 - TX1))

    RXKB=$((RX / 1024))
    TXKB=$((TX / 1024))

    sketchybar --set "$NAME" label="↓''${RXKB}K ↑''${TXKB}K"
  '';

  workspaceScript = pkgs.writeShellScript "workspace.sh" ''
    FOCUSED=$(aerospace list-workspaces --focused)

    if [ "$1" = "$FOCUSED" ]; then
      sketchybar --set "$NAME" \
        background.drawing=on \
        label.color=0xff282828 \
        icon.color=0xff282828
    else
      sketchybar --set "$NAME" \
        background.drawing=off \
        label.color=0xff80a8fc \
        icon.color=0xff80a8fc
    fi
  '';

in
{
  services.sketchybar = {
    enable = false;

    config = ''
      ACCENT=0xff80a8fc
      BG=0xff282828
      TRANSPARENT=0x00000000

      sketchybar --bar \
        position=top \
        height=37 \
        margin=16 \
        y_offset=10 \
        blur_radius=30 \
        color=0x40000000 \
        corner_radius=8

      default=(
        icon.font="OpenDyslexic Nerd Font:Bold:17.0"
        label.font="OpenDyslexic Nerd Font:Bold:14.0"
        icon.color=0xffffffff
        label.color=0xffffffff
        padding_left=10
        padding_right=10
      )

      sketchybar --default "''${default[@]}"

      sketchybar --add event aerospace_workspace_change

      ##### WORKSPACES #####

      for sid in $(aerospace list-workspaces --all); do
        sketchybar --add item space.$sid left \
          --subscribe space.$sid aerospace_workspace_change \
          --set space.$sid \
            icon="$sid" \
            label.drawing=off \
            background.color="$ACCENT" \
            background.corner_radius=5 \
            click_script="aerospace workspace $sid" \
            script="${workspaceScript} $sid"

        # FIX: Wire up the workspace indicator script so dots update
        sketchybar --subscribe space.$sid aerospace_workspace_change \
          --set space.$sid script="${workspaceIndicatorScript} $sid"
      done

      ##### LEFT ITEMS #####

      sketchybar --add item helium left \
        --set helium \
          icon="󰖟" \
          update_freq=60 \
          script="${heliumScript}"

      ##### RIGHT ITEMS #####

      sketchybar --add item clock right \
        --set clock \
          update_freq=30 \
          icon=􀧞 \
          script="${clockScript}"

      sketchybar --add item volume right \
        --set volume \
          script="${volumeScript}" \
        --subscribe volume volume_change

      # FIX: Use distinct network speed icon (not wifi icon)
      sketchybar --add item wifi_speed right \
        --set wifi_speed \
          update_freq=5 \
          icon="󰓅" \
          script="${wifiSpeedScript}"

      sketchybar --add item wifi right \
        --set wifi \
          update_freq=30 \
          icon="󰤨" \
          script="${wifiScript}"

      sketchybar --add item battery right \
        --set battery \
          update_freq=60 \
          script="${batteryScript}"

      sketchybar --add item cpu right \
        --set cpu \
          icon="󰻠" \
          update_freq=5 \
          script="${cpuScript}"

      sketchybar --update
    '';
  };

  services.aerospace = {
    enable = true;

    settings = {
      accordion-padding = 30;

      exec-on-workspace-change = [
        "${pkgs.bash}/bin/bash"
        "-c"
        "sketchybar --trigger aerospace_workspace_change"
      ];

      automatically-unhide-macos-hidden-apps = false;

      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";
      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;

      gaps = {
        inner = {
          horizontal = 18;
          vertical = 18;
        };

        outer = {
          top = 18;
          left = 18;
          right = 18;
          bottom = 18;
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
          # alt-f = "workspace F";
          alt-g = "workspace G";
          alt-h = "focus left";
          alt-i = "workspace I";
          alt-j = "focus down";
          alt-k = "focus up";
          alt-l = "focus right";
          alt-m = "workspace M";
          alt-minus = "resize smart -50";
          # alt-n = "workspace N";
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
          alt-shift-tab = "move-node-to-monitor --wrap-around next";
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
          alt-ctrl-s = "exec-and-forget screencapture -i -c";
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
}
