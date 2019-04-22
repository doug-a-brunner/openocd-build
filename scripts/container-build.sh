#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# This file is part of the GNU MCU Eclipse distribution.
#   (https://gnu-mcu-eclipse.github.io)
# Copyright (c) 2019 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software 
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Safety settings (see https://gist.github.com/ilg-ul/383869cbb01f61a51c4d).

if [[ ! -z ${DEBUG} ]]
then
  set ${DEBUG} # Activate the expand mode if DEBUG is anything but empty.
else
  DEBUG=""
fi

set -o errexit # Exit if command failed.
set -o pipefail # Exit if pipe failed.
set -o nounset # Exit if variable not set.

# Remove the initial space and instead use '\n'.
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Identify the script location, to reach, for example, the helper scripts.

build_script_path="$0"
if [[ "${build_script_path}" != /* ]]
then
  # Make relative path absolute.
  build_script_path="$(pwd)/$0"
fi

script_folder_path="$(dirname "${build_script_path}")"
script_folder_name="$(basename "${script_folder_path}")"

# =============================================================================

# Inner script to run inside Docker containers to build the 
# GNU MCU Eclipse RISC-V Embedded GCC distribution packages.

# For native builds, it runs on the host (macOS build cases,
# and development builds for GNU/Linux).

# -----------------------------------------------------------------------------

defines_script_path="${script_folder_path}/defs-source.sh"
echo "Definitions source script: \"${defines_script_path}\"."
source "${defines_script_path}"

# This file is generated by the host build script.
host_defines_script_path="${script_folder_path}/host-defs-source.sh"
echo "Host definitions source script: \"${host_defines_script_path}\"."
source "${host_defines_script_path}"

common_helper_functions_script_path="${script_folder_path}/helper/common-functions-source.sh"
echo "Common helper functions source script: \"${common_helper_functions_script_path}\"."
source "${common_helper_functions_script_path}"

common_functions_script_path="${script_folder_path}/common-functions-source.sh"
echo "Common functions source script: \"${common_functions_script_path}\"."
source "${common_functions_script_path}"

container_functions_script_path="${script_folder_path}/helper/container-functions-source.sh"
echo "Container helper functions source script: \"${container_functions_script_path}\"."
source "${container_functions_script_path}"

container_libs_functions_script_path="${script_folder_path}/${CONTAINER_LIBS_FUNCTIONS_SCRIPT_NAME}"
echo "Container libs functions source script: \"${container_libs_functions_script_path}\"."
source "${container_libs_functions_script_path}"

container_app_functions_script_path="${script_folder_path}/${CONTAINER_APPS_FUNCTIONS_SCRIPT_NAME}"
echo "Container app functions source script: \"${container_app_functions_script_path}\"."
source "${container_app_functions_script_path}"

# -----------------------------------------------------------------------------

if [ ! -z "#{DEBUG}" ]
then
  echo $@
fi

WITH_STRIP="y"
WITH_PDF="y"
WITH_HTML="n"
IS_DEVELOP=""
IS_DEBUG=""

JOBS=""

while [ $# -gt 0 ]
do

  case "$1" in

    --disable-strip)
      WITH_STRIP="n"
      shift
      ;;

    --without-pdf)
      WITH_PDF="n"
      shift
      ;;

    --with-pdf)
      WITH_PDF="y"
      shift
      ;;

    --without-html)
      WITH_HTML="n"
      shift
      ;;

    --with-html)
      WITH_HTML="y"
      shift
      ;;

    --jobs)
      JOBS=$2
      shift 2
      ;;

    --develop)
      IS_DEVELOP="y"
      shift
      ;;

    --debug)
      IS_DEBUG="y"
      shift
      ;;

    *)
      echo "Unknown action/option $1"
      exit 1
      ;;

  esac

done

if [ "${IS_DEBUG}" == "y" ]
then
  WITH_STRIP="n"
fi

# -----------------------------------------------------------------------------

start_timer

detect_container

prepare_xbb_env

prepare_xbb_extras

# -----------------------------------------------------------------------------

# The \x2C is a comma in hex; without this trick the regular expression
# that processes this string in the Makefile, silently fails and the 
# bfdver.h file remains empty.
BRANDING="${BRANDING}\x2C ${TARGET_BITS}-bit"

OPENOCD_PROJECT_NAME="openocd"
OPENOCD_GIT_COMMIT=${OPENOCD_GIT_COMMIT:-""}
README_OUT_FILE_NAME="README-${RELEASE_VERSION}.md"

LIBFTDI_PATCH=""
LIBUSB_W32_PATCH=""

# Keep them in sync with combo archive content.
if [[ "${RELEASE_VERSION}" =~ 0\.10\.0-7 ]]
then

  # ---------------------------------------------------------------------------

  OPENOCD_VERSION="0.10.0-7"
 
  OPENOCD_GIT_BRANCH=${OPENOCD_GIT_BRANCH:-"gnu-mcu-eclipse-dev"}
  OPENOCD_GIT_COMMIT=${OPENOCD_GIT_COMMIT:-"20463c28affea880d167b000192785a48f8974ca"}
  
  # ---------------------------------------------------------------------------

  LIBUSB1_VERSION="1.0.20"
  LIBUSB0_VERSION="0.1.5"
  LIBUSB_W32_VERSION="1.2.6.0"
  LIBFTDI_VERSION="1.2"
  LIBICONV_VERSION="1.15"
  HIDAPI_VERSION="0.8.0-rc1"

  LIBFTDI_PATCH="libftdi1-${LIBFTDI_VERSION}-cmake-FindUSB1.patch"
  LIBUSB_W32_PATCH="libusb-win32-${LIBUSB_W32_VERSION}-mingw-w64.patch"

  # ---------------------------------------------------------------------------
elif [[ "${RELEASE_VERSION}" =~ 0\.10\.0-8 ]]
then

  # ---------------------------------------------------------------------------

  OPENOCD_VERSION="0.10.0-8"
 
  OPENOCD_GIT_BRANCH=${OPENOCD_GIT_BRANCH:-"gnu-mcu-eclipse-dev"}
  OPENOCD_GIT_COMMIT=${OPENOCD_GIT_COMMIT:-"af359c18327b9852219ddab74c7fe175853f10ae"}
  
  # ---------------------------------------------------------------------------

  LIBUSB1_VERSION="1.0.20"
  LIBUSB0_VERSION="0.1.5"
  LIBUSB_W32_VERSION="1.2.6.0"
  LIBFTDI_VERSION="1.2"
  LIBICONV_VERSION="1.15"
  HIDAPI_VERSION="0.8.0-rc1"

  LIBFTDI_PATCH="libftdi1-${LIBFTDI_VERSION}-cmake-FindUSB1.patch"
  LIBUSB_W32_PATCH="libusb-win32-${LIBUSB_W32_VERSION}-mingw-w64.patch"

  # ---------------------------------------------------------------------------
elif [[ "${RELEASE_VERSION}" =~ 0\.10\.0-9 ]]
then

  # ---------------------------------------------------------------------------

  OPENOCD_VERSION="0.10.0-9"
 
  OPENOCD_GIT_BRANCH=${OPENOCD_GIT_BRANCH:-"gnu-mcu-eclipse-dev"}
  OPENOCD_GIT_COMMIT=${OPENOCD_GIT_COMMIT:-"d653938f45a5f040f771852f02128c4bcf8959ff"}
  
  # ---------------------------------------------------------------------------

  LIBUSB1_VERSION="1.0.20"
  LIBUSB0_VERSION="0.1.5"
  LIBUSB_W32_VERSION="1.2.6.0"
  LIBFTDI_VERSION="1.2"
  LIBICONV_VERSION="1.15"
  HIDAPI_VERSION="0.8.0-rc1"

  LIBFTDI_PATCH="libftdi1-${LIBFTDI_VERSION}-cmake-FindUSB1.patch"
  LIBUSB_W32_PATCH="libusb-win32-${LIBUSB_W32_VERSION}-mingw-w64.patch"

  # ---------------------------------------------------------------------------
elif [[ "${RELEASE_VERSION}" =~ 0\.10\.0-10 ]]
then

  # ---------------------------------------------------------------------------
  # Same as before, only a rerun.

  OPENOCD_VERSION="0.10.0-10"

  OPENOCD_GIT_BRANCH=${OPENOCD_GIT_BRANCH:-"gnu-mcu-eclipse-dev"}
  OPENOCD_GIT_COMMIT=${OPENOCD_GIT_COMMIT:-"aa6c7e9b884b028468b667ba3fab4f609c70471d"}
  
  # ---------------------------------------------------------------------------

  LIBUSB1_VERSION="1.0.20"
  LIBUSB0_VERSION="0.1.5"
  LIBUSB_W32_VERSION="1.2.6.0"
  LIBFTDI_VERSION="1.2"
  LIBICONV_VERSION="1.15"
  HIDAPI_VERSION="0.8.0-rc1"

  LIBFTDI_PATCH="libftdi1-${LIBFTDI_VERSION}-cmake-FindUSB1.patch"
  LIBUSB_W32_PATCH="libusb-win32-${LIBUSB_W32_VERSION}-mingw-w64.patch"

  # ---------------------------------------------------------------------------
elif [[ "${RELEASE_VERSION}" =~ 0\.10\.0-11 ]]
then

  # ---------------------------------------------------------------------------
  # Same as before, only a rerun.

  OPENOCD_VERSION="0.10.0-11"

  OPENOCD_GIT_BRANCH=${OPENOCD_GIT_BRANCH:-"gnu-mcu-eclipse-dev"}
  OPENOCD_GIT_COMMIT=${OPENOCD_GIT_COMMIT:-"dd1d90111a5a91e56c7fd5621d3efff63bbb6015"}
  
  # ---------------------------------------------------------------------------

  LIBUSB1_VERSION="1.0.20"
  LIBUSB0_VERSION="0.1.5"
  LIBUSB_W32_VERSION="1.2.6.0"
  LIBFTDI_VERSION="1.2"
  LIBICONV_VERSION="1.15"
  HIDAPI_VERSION="0.8.0-rc1"

  LIBFTDI_PATCH="libftdi1-${LIBFTDI_VERSION}-cmake-FindUSB1.patch"
  LIBUSB_W32_PATCH="libusb-win32-${LIBUSB_W32_VERSION}-mingw-w64.patch"

  # ---------------------------------------------------------------------------
elif [[ "${RELEASE_VERSION}" =~ 0\.10\.0-12 ]]
then

  # ---------------------------------------------------------------------------
  
  OPENOCD_VERSION="0.10.0-12"

  OPENOCD_GIT_BRANCH=${OPENOCD_GIT_BRANCH:-"gnu-mcu-eclipse-dev"}
  OPENOCD_GIT_COMMIT=${OPENOCD_GIT_COMMIT:-"23ad80df43ac31ce147359f18f2ef9e0e62df794"}
  
  # ---------------------------------------------------------------------------

  LIBUSB1_VERSION="1.0.22"
  LIBUSB0_VERSION="0.1.5"
  LIBUSB_W32_VERSION="1.2.6.0"
  LIBFTDI_VERSION="1.4"
  LIBICONV_VERSION="1.15"
  HIDAPI_VERSION="0.8.0-rc1"

  # LIBFTDI_PATCH="libftdi1-${LIBFTDI_VERSION}-cmake-FindUSB1.patch"
  LIBUSB_W32_PATCH="libusb-win32-${LIBUSB_W32_VERSION}-mingw-w64.patch"

  # ---------------------------------------------------------------------------
else
  echo "Unsupported version ${RELEASE_VERSION}."
  exit 1
fi

# -----------------------------------------------------------------------------

OPENOCD_SRC_FOLDER_NAME=${OPENOCD_SRC_FOLDER_NAME:-"${OPENOCD_PROJECT_NAME}.git"}
OPENOCD_GIT_URL=${OPENOCD_GIT_URL:-"https://github.com/gnu-mcu-eclipse/openocd.git"}

# Used in the licenses folder.
OPENOCD_FOLDER_NAME="openocd-${OPENOCD_VERSION}"

# -----------------------------------------------------------------------------

echo
echo "Here we go..."
echo

# -----------------------------------------------------------------------------
# Build dependent libraries.

do_libusb1
if [ "${TARGET_PLATFORM}" == "win32" ]
then
  do_libusb_w32
else
  do_libusb0
fi

do_libftdi

do_libiconv

do_hidapi

# -----------------------------------------------------------------------------

do_openocd

run_openocd

# -----------------------------------------------------------------------------

check_binaries

copy_distro_files

create_archive

# Change ownership to non-root Linux user.
fix_ownership

# -----------------------------------------------------------------------------

stop_timer

exit 0

# -----------------------------------------------------------------------------
