#!/usr/bin/env bash
WORKSPACE_NAME=$1
focused_output=$(i3-msg -t get_workspaces \
    | jq -r '.[] | select(.focused==true).output')
target_workspaces_output=$(i3-msg -t get_workspaces \
    | jq -r ".[] | select(.name==\"${WORKSPACE_NAME}\").output")

if [ "${target_workspaces_output}" == "" -o "${focused_output}" == "${target_workspaces_output}" ]; then
    i3-msg -- workspace number $WORKSPACE_NAME
else
    i3-msg -- workspace --no-auto-back-and-forth number $WORKSPACE_NAME
    i3-msg -- move workspace to output next
fi
