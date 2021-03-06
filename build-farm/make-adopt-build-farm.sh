#!/bin/bash

################################################################################
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################

set -e

PLATFORM_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

## Very very build farm specific configuration

export OPERATING_SYSTEM
OPERATING_SYSTEM=$(echo "${TARGET_OS}" | tr '[:upper:]' '[:lower:]')

export JAVA_FEATURE_VERSION
JAVA_FEATURE_VERSION=$(echo "${JAVA_TO_BUILD}" | tr -d "[:alpha:]")

if [ -z "${JAVA_FEATURE_VERSION}" ]
then
  # Use Adopt API to get the JDK Head number
  echo "This appears to be JDK Head. Querying the Adopt API to get the JDK HEAD Number (https://api.adoptopenjdk.net/v3/info/available_releases)..."
  JAVA_FEATURE_VERSION=$(curl https://api.adoptopenjdk.net/v3/info/available_releases | awk '/tip_version/{print$2}')
    
  # Checks the api request was successfull and the return value is a number
  if [ -z "${JAVA_FEATURE_VERSION}" ] || ! [[ "${JAVA_FEATURE_VERSION}" -gt 0 ]]
  then
    echo "Failed to query or parse the adopt api"
    exit 1
  fi
  echo "JAVA_FEATURE_VERSION is ${JAVA_FEATURE_VERSION}"
fi

echo "BUILD TYPE: "
echo "VERSION: ${JAVA_TO_BUILD}"
echo "ARCHITECTURE ${ARCHITECTURE}"
echo "VARIANT: ${VARIANT}"
echo "OS: ${OPERATING_SYSTEM}"
echo "SCM_REF: ${SCM_REF}"
OPTIONS=""

EXTENSION=""
# shellcheck disable=SC2034
CONFIGURE_ARGS_FOR_ANY_PLATFORM=${CONFIGURE_ARGS:-""}
BUILD_ARGS=${BUILD_ARGS:-""}
VARIANT_ARG=""

if [ -z "${JDK_BOOT_VERSION}" ]
then
  echo "Detecting boot jdk for: ${JAVA_TO_BUILD}"
  echo "Found build version: ${JAVA_FEATURE_VERSION}"
  JDK_BOOT_VERSION=$(($JAVA_FEATURE_VERSION-1))
fi
echo "Required boot JDK version: ${JDK_BOOT_VERSION}"

case "${JDK_BOOT_VERSION}" in
      "7")    export JDK_BOOT_DIR="${JDK_BOOT_DIR:-$JDK7_BOOT_DIR}";;
      "8")    export JDK_BOOT_DIR="${JDK_BOOT_DIR:-$JDK8_BOOT_DIR}";;
      "9")    export JDK_BOOT_DIR="${JDK_BOOT_DIR:-$JDK9_BOOT_DIR}";;
      "10")   export JDK_BOOT_DIR="${JDK_BOOT_DIR:-$JDK10_BOOT_DIR}";;
      "11")   export JDK_BOOT_DIR="${JDK_BOOT_DIR:-$JDK11_BOOT_DIR}";;
      "12")   export JDK_BOOT_DIR="${JDK_BOOT_DIR:-$JDK12_BOOT_DIR}";;
      "13")   export JDK_BOOT_DIR="${JDK_BOOT_DIR:-$JDK13_BOOT_DIR}";;
      "14")   export JDK_BOOT_DIR="${JDK_BOOT_DIR:-$JDK14_BOOT_DIR}";;
      *)      export JDK_BOOT_DIR="${JDK_BOOT_DIR:-$JDK15_BOOT_DIR}";;
esac

if [ ! -d "${JDK_BOOT_DIR}" ]
then
  echo Setting JDK_BOOT_DIR to \$JAVA_HOME
  export JDK_BOOT_DIR="${JAVA_HOME}"
fi

echo "Boot jdk directory: ${JDK_BOOT_DIR}:"
${JDK_BOOT_DIR}/bin/java -version 2>&1 | sed 's/^/BOOT JDK: /'
java -version 2>&1 | sed 's/^/JDK IN PATH: /g'

if [ "${RELEASE}" == "true" ]; then
  OPTIONS="${OPTIONS} --release --clean-libs"
fi

if [ "${RELEASE}" == "true" ] && [ "${VARIANT}" != "openj9" ]; then
    export TAG="${SCM_REF}"
else
    export BRANCH="${SCM_REF}"
fi


if [ ! -z "${TAG}" ]; then
  OPTIONS="${OPTIONS} --tag $TAG"
fi

if [ ! -z "${BRANCH}" ]
then
  OPTIONS="${OPTIONS} --disable-shallow-git-clone -b ${BRANCH}"
fi

echo "BRANCH: ${BRANCH} (For release either BRANCH or TAG should be set)"
echo "TAG: ${TAG}"

# shellcheck source=build-farm/set-platform-specific-configurations.sh
source "${PLATFORM_SCRIPT_DIR}/set-platform-specific-configurations.sh"

echo "Filename will be: $FILENAME"

export BUILD_ARGS="${BUILD_ARGS} --use-jep319-certs"

echo "$PLATFORM_SCRIPT_DIR/../makejdk-any-platform.sh" --clean-git-repo --jdk-boot-dir "${JDK_BOOT_DIR}" --configure-args "${CONFIGURE_ARGS_FOR_ANY_PLATFORM}" --target-file-name "${FILENAME}" ${TAG_OPTION} ${OPTIONS} ${BUILD_ARGS} ${VARIANT_ARG} "${JAVA_TO_BUILD}"

# shellcheck disable=SC2086
bash -c "$PLATFORM_SCRIPT_DIR/../makejdk-any-platform.sh --clean-git-repo --jdk-boot-dir ${JDK_BOOT_DIR} --configure-args \"${CONFIGURE_ARGS_FOR_ANY_PLATFORM}\" --target-file-name ${FILENAME} ${TAG_OPTION} ${OPTIONS} ${BUILD_ARGS} ${VARIANT_ARG} ${JAVA_TO_BUILD}"
