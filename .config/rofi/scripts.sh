#!/bin/bash

list=(
    "ss"    "import ~/tmp.png"
)

for (( i=1; i<=$((${#list[@]}/2)); i++ )); do
    [[ -z "$@" ]] && echo "${i}. ${list[$i*2-2]}" && continue
    [[ "$@" == "${i}. ${list[$i*2-2]}" ]] && command="${list[$i*2-1]}" && break
done
eval "${command:-:}"
