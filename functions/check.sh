#!/bin/bash
# LGSM fn_check function
# Author: Daniel Gibbs
# Website: http://gameservermanagers.com
lgsm_version="271215"

# Description: Overall function for managing checks.
# Runs checks that will either halt on or fix an issue.

fn_module_compare() {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}


check_root.sh

if [ "${cmd}" != "install" ]; then
	check_systemdir.sh
fi

no_check_logs=( debug details install map-compressor )
fn_module_compare "${cmd}" "${no_check_logs[@]}"
if [ $? != 0 ]; then
	check_logs.sh
fi

check_ip=( debug )
fn_module_compare "${cmd}" "${no_check_logs[@]}"
if [ $? != 0 ]; then
	check_ip.sh
fi

check_ip=( debug )
fn_module_compare "${cmd}" "${no_check_logs[@]}"
if [ $? != 0 ]; then
	check_steamuser.sh
	check_steamcmd.sh
fi

check_ip=( start )
fn_module_compare "${cmd}" "${no_check_logs[@]}"
if [ $? != 0 ]; then
	check_tmux.sh
fi