#!/bin/bash
# LGSM update_factorio.sh function
# Author: Daniel Gibbs
# Contributor: Kristian Polso
# Website: https://gameservermanagers.com
# Description: Handles updating of Factorio servers.

local commandname="UPDATE"
local commandaction="Update"
local function_selfname="$(basename $(readlink -f "${BASH_SOURCE[0]}"))"

fn_update_factorio_dl(){
	fn_fetch_file "https://www.factorio.com/get-download/${availablebuild}/headless/${factorioarch}" "${tmpdir}" "factorio_headless_${factorioarch}-${availablebuild}.tar.gz"
	fn_dl_extract "${tmpdir}" "factorio_headless_${factorioarch}-${availablebuild}.tar.gz" "${tmpdir}"
	echo -e "copying to ${filesdir}...\c"
	fn_script_log "Copying to ${filesdir}"
	cp -R "${tmpdir}/factorio/"* "${filesdir}"
	local exitcode=$?
	if [ ${exitcode} -eq 0 ]; then
		fn_print_ok_eol_nl
	else
		fn_print_fail_eol_nl
	fi
}

fn_update_factorio_currentbuild(){
	# Gets current build info
	# Checks if current build info is available. If it fails, then a server restart will be forced to generate logs.
	if [ ! -f "${consolelogdir}/${servicename}-console.log" ]; then
		fn_print_error "Checking for update: Factorio.com"
		sleep 1
		fn_print_error_nl "Checking for update: Factorio.com: No logs with server version found"
		fn_script_log_error "Checking for update: Factorio.com: No logs with server version found"
		sleep 1
		fn_print_info_nl "Checking for update: Factorio.com: Forcing server restart"
		fn_script_log_info "Checking for update: Factorio.com: Forcing server restart"
		sleep 1
		exitbypass=1
		command_stop.sh
		exitbypass=1
		command_start.sh
		sleep 1
		# Check again and exit on failure.
		if [ ! -f "${consolelogdir}/${servicename}-console.log" ]; then
			fn_print_fail_nl "Checking for update: Factorio.com: Still No logs with server version found"
			fn_script_log_fatal "Checking for update: Factorio.com: Still No logs with server version found"
			core_exit.sh
		fi
	fi

	# Get current build from logs
	currentbuild=$(cat "${consolelogdir}"/"${servicename}"-console.log 2> /dev/null | sort | grep -oP '(?<=Factorio ).*?(?= \()')
	if [ -z "${currentbuild}" ]; then
		fn_print_error_nl "Checking for update: Factorio.com: Current build version not found"
		fn_script_log_error "Checking for update: Factorio.com: Current build version not found"
		sleep 1
		fn_print_info_nl "Checking for update: Factorio.com: Forcing server restart"
		fn_script_log_info "Checking for update: Factorio.com: Forcing server restart"
		exitbypass=1
		command_stop.sh
		exitbypass=1
		command_start.sh
		currentbuild=$(cat "${consolelogdir}"/"${servicename}"-console.log 2> /dev/null | sort | grep -oP '(?<=Factorio ).*?(?= /)')
		if [ -z "${currentbuild}" ]; then
			fn_print_fail_nl "Checking for update: Factorio.com: Current build version still not found"
			fn_script_log_fatal "Checking for update: Factorio.com: Current build version still not found"
			core_exit.sh
		fi
	fi
}

fn_update_factorio_arch(){
	# Factorio is linux64 only for now
	factorioarch="linux64"
}

fn_update_factorio_availablebuild(){
	# Gets latest build info.
	availablebuild=$(curl -s https://www.factorio.com/download-headless/stable | grep 'headless/linux64' | head -n 1 | grep -oP '(?<=get-download/).*?(?=/)')
	sleep 1

	# Checks if availablebuild variable has been set
	if [ -z "${availablebuild}" ]; then
		fn_print_fail "Checking for update: Factorio.com"
		sleep 1
		fn_print_fail "Checking for update: Factorio.com: Not returning version info"
		fn_script_log_fatal "Failure! Checking for update: Factorio.com: Not returning version info"
		core_exit.sh
	else
		fn_print_ok "Checking for update: Factorio.com"
		fn_script_log_pass "Checking for update: Factorio.com"
		sleep 1
	fi
}

fn_update_factorio_compare(){
	# Removes dots so if can compare version numbers
	currentbuilddigit=$(echo "${currentbuild}"|tr -cd '[:digit:]')
	availablebuilddigit=$(echo "${availablebuild}"|tr -cd '[:digit:]')

	if [ "${currentbuilddigit}" -ne "${availablebuilddigit}" ]; then
		echo -e "\n"
		echo -e "Update available:"
		sleep 1
		echo -e "	Current build: ${red}${currentbuild} ${factorioarch}${default}"
		echo -e "	Available build: ${green}${availablebuild} ${factorioarch}${default}"
		echo -e ""
		sleep 1
		echo ""
		echo -en "Applying update.\r"
		sleep 1
		echo -en "Applying update..\r"
		sleep 1
		echo -en "Applying update...\r"
		sleep 1
		echo -en "\n"
		fn_script_log "Update available"
		fn_script_log "Current build: ${currentbuild}"
		fn_script_log "Available build: ${availablebuild}"
		fn_script_log "${currentbuild} > ${availablebuild}"

		unset updateonstart

		check_status.sh
		if [ "${status}" == "0" ]; then
			fn_update_factorio_dl
			exitbypass=1
			command_start.sh
			exitbypass=1
			command_stop.sh
		else
			exitbypass=1
			command_stop.sh
			fn_update_factorio_dl
			exitbypass=1
			command_start.sh
		fi
		alert="update"
		alert.sh
	else
		echo -e "\n"
		echo -e "No update available:"
		echo -e "	Current version: ${green}${currentbuild}${default}"
		echo -e "	Available version: ${green}${availablebuild}${default}"
		echo -e ""
		fn_print_ok_nl "No update available"
		fn_script_log_info "Current build: ${currentbuild}"
		fn_script_log_info "Available build: ${availablebuild}"
	fi
}


fn_update_factorio_arch
if [ "${installer}" == "1" ]; then
	fn_update_factorio_availablebuild
	fn_update_factorio_dl
else
	# Checks for server update from github.com
	fn_print_dots "Checking for update: github.com"
	fn_script_log_info "Checking for update: github.com"
	sleep 1
	fn_update_factorio_currentbuild
	fn_update_factorio_availablebuild
	fn_update_factorio_compare
fi
