#!/usr/bin/osascript

# @raycast.schemaVersion 1
# @raycast.title z
# @raycast.mode silent
# @raycast.icon 🤖

tell application "Zed" to activate
delay 0.2

tell application "System Events"
    keystroke "N" using {command down, shift down}
end tell
