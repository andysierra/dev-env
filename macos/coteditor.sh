#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title coteditor
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖

osascript <<EOF
tell application "CotEditor"
    make new document
    activate
end tell
EOF
