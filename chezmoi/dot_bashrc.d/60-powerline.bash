POWERLINE_DIR=""
for candidate in "$HOME"/.local/lib/python*/site-packages/powerline /usr/lib/python*/site-packages/powerline /usr/local/lib/python*/site-packages/powerline; do
  if [[ -d "$candidate" ]]; then
    POWERLINE_DIR="$candidate"
  fi
done

if [[ -n "$POWERLINE_DIR" && -f "$POWERLINE_DIR/bindings/bash/powerline.sh" ]]; then
  source "$POWERLINE_DIR/bindings/bash/powerline.sh"
fi

export POWERLINE_DIR
