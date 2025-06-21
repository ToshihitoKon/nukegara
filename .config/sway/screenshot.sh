#!/usr/bin/env bash
slurp | grim -g - tmp.png
cat tmp.png | wl-copy
