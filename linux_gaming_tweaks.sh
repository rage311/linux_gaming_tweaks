#!/usr/bin/env bash
# Also requires perl

# This is especially useful to launch automatically when you run a (Steam)
# game by adding it to the game's "Launch Options" in Steam.
# (Right-click the game in the library list, click "Properties",
# click "Set Launch Options...". eg:
# $HOME/bin/linux_gaming_tweaks.sh start; %command%; $HOME/bin/linux_gaming_tweaks.sh stop
# (make sure to chmod +x linux_gaming_tweaks.sh before you try that)

###### configuration
LOG_FILE="$HOME/Documents/linux_gaming_tweaks.log"

# Get this value by looking at output of "xinput"
MOUSE_STRING='SteelSeries Rival Gaming Mouse'
# https://wiki.freedesktop.org/xorg/Development/Documentation/PointerAcceleration/#index2h2
# -1 is no acceleration, 0 is default
POINTER_ACCEL_GAMING=-1
POINTER_ACCEL_NORMAL=0

DISPLAY_ADAPTER='DFP-0'
GPU_NUMBER=0
# Between 0 and 1023 -- 0 is off, 1023 is full vibrance
VIBRANCE_ON_SETTING=1023
VIBRANCE_OFF_SETTING=0

COMPOSITOR_NAME='compton'
COMPOSITOR_START='nohup compton --paint-on-overlay --backend glx --unredir-if-possible &'

# This disables extraneous monitors and disables the full composition pipeline
X_META_MODE_GAMING='DVI-I-1: 1920x1080_100.00 +0+0 { ForceFullCompositionPipeline = Off }'
X_META_MODE_NORMAL='DVI-D-0: 1920x1080_60.00 +0+0 { ForceFullCompositionPipeline = On }, DVI-I-1: 1920x1080_100.00 +1920+0 { ForceFullCompositionPipeline = On }, DP-1: 1920x1080_60.00 +3840+0 { ForceFullCompositionPipeline = On }'
######


function set_accel() {
  while read -r line; do
    MOUSE_ID=$(echo "$line" | perl -ne 'print $1 if /.+id=(\d+)/')
    if ( xinput list-props "$MOUSE_ID" | grep -q 'Device Accel Profile' ); then
      xinput set-prop "$MOUSE_ID" 'Device Accel Profile' "$1"
    # Different name in Xorg 1.19/libinput/xf86-input-libinput
    elif ( xinput list-props "$MOUSE_ID" | grep -q 'libinput Accel Speed' ); then
      xinput set-prop "$MOUSE_ID" 'libinput Accel Speed' "$1"
    else
      echo "Unable to set acceleration for MOUSE_ID: $MOUSE_ID" >>"$LOG_FILE"
    fi
  done < <(xinput | egrep "${MOUSE_STRING}.+pointer")
}

# Seems to only work when using steam-native?
function set_digital_vibrance() {
  nvidia-settings -c ':0' -a \
    "[gpu:$GPU_NUMBER]/DigitalVibrance[$DISPLAY_ADAPTER]=$1" \
    >>"$LOG_FILE" 2>&1
}

function kill_compositor() {
  pkill "$COMPOSITOR_NAME"
}

function start_compositor() {
  $COMPOSITOR_START 2>/dev/null
}

function toggle_redshift() {
  systemctl --user "$1" redshift
}

function set_x_mode() {
  nvidia-settings --assign CurrentMetaMode="$1"
}


DIRECTION="$1"

if [ ! -z "$DIRECTION" ]; then
  date >>"$LOG_FILE"
  echo "$DIRECTION" >>"$LOG_FILE"
  if [ "$DIRECTION" == "start" ]; then
    set_x_mode "$X_META_MODE_GAMING"
    set_accel "$POINTER_ACCEL_GAMING"
    set_digital_vibrance "$VIBRANCE_ON_SETTING"
    kill_compositor
    toggle_redshift "stop"
  elif [ "$DIRECTION" == "stop" ]; then
    set_x_mode "$X_META_MODE_NORMAL"
    set_accel "$POINTER_ACCEL_NORMAL"
    set_digital_vibrance "$VIBRANCE_OFF_SETTING"
    start_compositor
    toggle_redshift "start"
  else
    echo "invalid argument"
    exit 3
  fi
else
  echo "requires an argument ( start | stop )"
  exit 1
fi
