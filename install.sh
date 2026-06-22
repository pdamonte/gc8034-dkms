#!/usr/bin/env bash
set -euo pipefail

PACKAGE_NAME=gc8034-dkms
PACKAGE_VERSION=0.1.1
MODULE_NAME=gc8034
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DKMS_SRC="/usr/src/${PACKAGE_NAME}-${PACKAGE_VERSION}"
KREL="${1:-$(uname -r)}"
MISSING_PACKAGES=()

add_missing_package() {
	local package="$1"
	local existing

	for existing in "${MISSING_PACKAGES[@]}"; do
		[ "$existing" = "$package" ] && return 0
	done

	MISSING_PACKAGES+=("$package")
}

require_command() {
	local command="$1"
	local package="$2"

	if ! command -v "$command" >/dev/null 2>&1; then
		add_missing_package "$package"
	fi
}

check_dependencies() {
	require_command dkms dkms
	require_command make build-essential
	require_command gcc build-essential
	require_command media-ctl v4l-utils
	require_command v4l2-ctl v4l-utils
	require_command python3 python3

	if command -v python3 >/dev/null 2>&1; then
		if ! python3 -c 'from PIL import Image' >/dev/null 2>&1; then
			add_missing_package python3-pil
		fi
	fi

	if [ ! -e "/lib/modules/${KREL}/build/Makefile" ]; then
		add_missing_package "linux-headers-${KREL}"
	fi

	if [ "${#MISSING_PACKAGES[@]}" -gt 0 ]; then
		echo "Missing required Ubuntu packages:" >&2
		printf '  %s\n' "${MISSING_PACKAGES[@]}" >&2
		echo >&2
		echo "Install them first:" >&2
		printf '  sudo apt update && sudo apt install' >&2
		printf ' %q' "${MISSING_PACKAGES[@]}" >&2
		echo >&2
		exit 1
	fi
}

if [ "$(id -u)" -ne 0 ]; then
	echo "Run as root: sudo $0 [kernel-release]" >&2
	exit 1
fi

check_dependencies

if dkms status -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" | grep -q .; then
	dkms remove -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" --all || true
fi

rm -rf "${DKMS_SRC}"
install -d "${DKMS_SRC}"
cp -a "${SRC_DIR}/." "${DKMS_SRC}/"

dkms add -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}"
dkms build -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" -k "${KREL}"
dkms install -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" -k "${KREL}"

modprobe -r "${MODULE_NAME}" 2>/dev/null || true
modprobe "${MODULE_NAME}"

echo "${MODULE_NAME}" >/etc/modules-load.d/gc8034.conf
modinfo -k "${KREL}" -F filename "${MODULE_NAME}" || true
