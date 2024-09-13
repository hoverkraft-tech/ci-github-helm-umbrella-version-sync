#!/bin/bash

set -eu -o pipefail

# Path to the umbrella chart
CHART_PATH=${1:-"charts"}

# Get the version of the root chart
echo "Getting the version of the root chart"
ROOT_VERSION=$(yq e '.version' "$CHART_PATH/Chart.yaml")
echo "Root chart version is $ROOT_VERSION"

# Update the version of all subcharts
echo "Updating the version of all subcharts to $ROOT_VERSION"
find "$CHART_PATH/charts" -type f -name "Chart.yaml" | while read -r chart_file; do
  subchart_dir=$(dirname "$chart_file")
  real_subchart_dir=$(realpath "$subchart_dir")
  # Process the real_subchart_dir
  echo "Updating version of subchart $real_subchart_dir"
  yq e -i ".version = \"$ROOT_VERSION\"" "$chart_file"
  echo "Updated version of subchart $real_subchart_dir to $ROOT_VERSION"
done

# Rebuild Helm dependencies
echo "Rebuilding Helm dependencies"
helm dependency build "$CHART_PATH"

echo "All subchart versions have been aligned to version $ROOT_VERSION and dependencies updated"
