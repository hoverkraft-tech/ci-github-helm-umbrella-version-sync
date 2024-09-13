#!/bin/bash

set -eu -o pipefail

# -------------------------------------------------------------------
# Functions
# -------------------------------------------------------------------
# Function to get the version of the root chart
get_root_version() {
  local root_version
  root_version=$(yq e '.version' "$CHART_PATH/Chart.yaml")
  echo "$root_version"
}

# Function to update the version of all subcharts
update_subchart_versions() {
  local root_version="$1"
  echo "Updating the version of all subcharts to $root_version"
  find "$CHART_PATH/charts" -type f -name "Chart.yaml" | while read -r chart_file; do
    subchart_dir=$(dirname "$chart_file")
    real_subchart_dir=$(realpath "$subchart_dir")
    echo "Updating version of subchart $real_subchart_dir"
    yq e -i ".version = \"$root_version\"" "$chart_file"
    echo "Updated version of subchart $real_subchart_dir to $root_version"
  done
}

# Function to update the root Chart.yaml dependencies
update_dependencies() {
  root_chart="$CHART_PATH/Chart.yaml"
  echo "Updating dependencies in $root_chart"

  find "$CHART_PATH/charts" -type f -name "Chart.yaml" | while read -r chart_file; do
    subchart_dir=$(dirname "$chart_file")
    real_subchart_dir=$(realpath "$subchart_dir")
    subchart_name=$(yq e '.name' "$chart_file")
    subchart_version=$(yq e '.version' "$chart_file")

    echo "Updating dependency for $subchart_name to version $subchart_version"

    # Update the dependency in the root Chart.yaml
    yq e -i "
      .dependencies[] |= (
        select(.name == \"$subchart_name\") |
        .version = \"$subchart_version\"
      )
    " "$root_chart"
  done
}

# Function to rebuild Helm dependencies
rebuild_helm_dependencies() {
  if [ -f "$CHART_PATH/Chart.lock" ]; then
    echo "Rebuilding Helm dependencies using 'helm dependency update'"
    helm dependency update "$CHART_PATH"
  else
    echo "Chart.lock not found, building Helm dependencies using 'helm dependency build'"
    helm dependency build "$CHART_PATH"
  fi
}

# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------
# Path to the umbrella chart
CHART_PATH=${1:-"charts"}

# Get the version of the root chart
echo "Getting the version of the root chart"
ROOT_VERSION="$(get_root_version)"
echo "Root chart version is $ROOT_VERSION"

# Update the version of all subcharts
update_subchart_versions "$ROOT_VERSION"

# Update dependencies in the root Chart.yaml
update_dependencies

# Rebuild Helm dependencies
rebuild_helm_dependencies

echo "All subchart versions have been aligned to version $ROOT_VERSION and dependencies updated"
