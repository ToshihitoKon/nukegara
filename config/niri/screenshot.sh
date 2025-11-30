#!/usr/bin/env bash

grim -g "$(slurp)" -t png - | tee /tmp/ss.png | wl-copy --primary
