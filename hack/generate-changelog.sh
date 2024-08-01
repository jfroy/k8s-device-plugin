#!/usr/bin/env bash

# Copyright (c) 2024, NVIDIA CORPORATION.  All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o pipefail
this=`basename $0`

usage () {
cat << EOF
Generate a changelog for the specified tag
Usage: $this --since <tag> [--remote <remote_name>]

Options:
  --since     specify the tag to start the changelog from (default: latest tag)
  --version   specify the version to be released
  --help/-h   show this help and exit

EOF
}

VERSION=""
REFERENCE=

# Parse command line options
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --since)
        REFERENCE="$2"
        shift # past argument
        shift # past value
        ;;
        --version)
        VERSION="$2"
        shift # past argument
        shift # past value
        ;;
        --help/-h)  usage
            exit 0
            ;;
        *)  usage
            exit 1
            ;;
    esac
done

# Fetch the latest tags from the remote
remote=$( git remote -v | grep -E "NVIDIA/k8s-device-plugin(\.git)?\s" | grep -oE "^[a-z]+" | sort -u )
git fetch ${remote} --tags

# if REFERENCE is not set, get the latest tag
if [ -z "$REFERENCE" ]; then
    most_recent_tag=$(git tag --sort=-creatordate | head -1)
    if [ "${VERSION}" == "${most_recent_tag}" ]; then
        REFERENCE=$(git tag --sort=-creatordate | head -2 | tail -1)
    else
        REFERENCE=${most_recent_tag}
    fi
fi

SHA=$(git rev-parse ${VERSION})
if [[ $? -ne 0 ]]; then
    SHA="HEAD"
fi

# Print the changelog
echo "## Changelog"
echo ""
echo "### Version $VERSION"

# Iterate over the commit messages and ignore the ones that start with "Merge" or "Bump"
git log --pretty=format:"%s" $REFERENCE..$SHA | grep -Ev "(^Merge )|(^Bump)|(no-rel-?note)|(^---)" |  sed 's/^\(.*\)/- \1/g'
