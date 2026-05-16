#! /bin/bash
export POWERLINE_DIR="$(readlink -f "$((find . -path './.local/lib/python*/site-packages/powerline' | sort -r ; find /usr/lib/ -path '/usr/lib/python*/site-packages/powerline' | sort -r) | head -1)")"
killall lemonbar
python $POWERLINE_DIR/bindings/lemonbar/powerline-lemonbar.py -i3 -- -f "Inconsolata Regular-10"

