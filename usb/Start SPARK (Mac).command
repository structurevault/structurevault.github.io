#!/bin/bash
# SPARK Centre USB updater (Mac). Downloads the latest site when GitHub has a new version,
# otherwise opens the copy already on this USB.
cd "$(dirname "$0")" || exit 1
REPO="structurevault/structurevault.github.io"
BRANCH="main"
SITE="site"
mkdir -p "$SITE"
stamp() { printf 'window.SPARK_USB={status:"%s"};\n' "$1" > "$SITE/spark-version.js"; }
now() { date '+%-d %b %Y, %-I:%M %p'; }

echo ""
echo "  SPARK Centre - checking for updates..."
LATEST=$(curl -fsS -m 15 -H "Accept: application/vnd.github.sha" -H "User-Agent: spark-usb-updater" \
  "https://api.github.com/repos/$REPO/commits/$BRANCH" 2>/dev/null)
CURRENT=$(cat "$SITE/.spark-commit" 2>/dev/null)

if [ -z "$LATEST" ]; then
  echo "  No internet (or GitHub is busy). Opening the copy on this USB."
  [ -f "$SITE/index.html" ] && stamp "offline copy"
elif [ "$LATEST" = "$CURRENT" ] && [ -f "$SITE/index.html" ]; then
  echo "  Already up to date."
  stamp "up to date · checked $(now)"
else
  echo "  Downloading the latest version..."
  TMP=$(mktemp -d)
  if curl -fL --progress-bar -o "$TMP/site.zip" "https://codeload.github.com/$REPO/zip/$LATEST" \
     && unzip -q "$TMP/site.zip" -d "$TMP/x"; then
    SRC=$(find "$TMP/x" -mindepth 1 -maxdepth 1 -type d | head -1)
    rsync -rt --delete --exclude '.*' --exclude 'usb/' --exclude 'spark-version.js' "$SRC/" "$SITE/"
    echo "$LATEST" > "$SITE/.spark-commit"
    stamp "updated $(now)"
    echo "  Updated."
  else
    echo "  Download failed. Opening the copy on this USB."
  fi
  rm -rf "$TMP"
fi

if [ -f "$SITE/index.html" ]; then
  open "$SITE/index.html"
else
  echo ""
  echo "  There's no copy of SPARK Centre on this USB yet."
  echo "  Connect to the internet and run this again."
  read -r -p "  Press Enter to close."
fi
