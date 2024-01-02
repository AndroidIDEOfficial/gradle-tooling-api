#!/usr/bin/env bash

#
#  This file is part of AndroidIDE.
#
#  AndroidIDE is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  AndroidIDE is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#   along with AndroidIDE.  If not, see <https://www.gnu.org/licenses/>.
#

set -eu

script_dir=$(dirname $(realpath $0))

group=com.itsaky.androidide.gradle
artifactId=gradle-tooling-api
serverId=ossrh

PUBLISH_URL=https://s01.oss.sonatype.org/service/local/staging/deploy/maven2/

DOWNLOAD_VERSION=${1:-""}
PUBLISH_VERSION=${2:-""}
DOWNLOAD_BASE_URL="https://repo.gradle.org/gradle/libs-releases/org/gradle/$artifactId"

if [[ "$DOWNLOAD_VERSION" == "" ]]; then
  echo "Usage: $0 <gradle-tooling-api-version> <publishing-version>"
  echo "Example: $0 8.5 8.5-r3"
  exit 1
fi

if [[ "$PUBLISH_VERSION" == "" ]]; then
  PUBLISH_VERSION="$DOWNLOAD_VERSION"
fi

file_base=$script_dir/target/$artifactId-${DOWNLOAD_VERSION}

if ! [[ -f "$file_base.jar" && "$file_base-sources.jar" && "$file_base-javadoc.jar" ]]; then
  echo "$file_base does not exist. Downloading..."

  url="$DOWNLOAD_BASE_URL/$DOWNLOAD_VERSION/$artifactId-$DOWNLOAD_VERSION"

  mkdir -p "$(dirname $file_base)"

  # JAR file
  wget "$url.jar" -O "$file_base.jar" || exit 1

  # Sources JAR
  wget "$url-sources.jar" -O "$file_base-sources.jar" || exit 1

  # Javadoc JAR
  wget "$url-javadoc.jar" -O "$file_base-javadoc.jar" || exit 1
fi


cp "$script_dir/pom.xml.in" "$script_dir/target/pom.xml"

sed -i "s|@@GROUP@@|$group|g" $script_dir/target/pom.xml
sed -i "s|@@ARTIFACT@@|$artifactId|g" $script_dir/target/pom.xml
sed -i "s|@@VERSION@@|$PUBLISH_VERSION|g" $script_dir/target/pom.xml

exec mvn gpg:sign-and-deploy-file -e -Durl=$PUBLISH_URL \
                       -DrepositoryId=$serverId \
                       -Dfile="$file_base.jar" \
                       -Dsources="$file_base-sources.jar" \
                       -Djavadoc="$file_base-javadoc.jar" \
                       -DpomFile=$script_dir/target/pom.xml \
                       -DgroupId=$group \
                       -DartifactId=$artifactId \
                       -Dversion=$PUBLISH_VERSION \
                       -Dpackaging=jar \
                       -DrepositoryLayout=default
