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
for subchart in "$CHART_PATH/charts"/*; do
  echo "Updating version of subchart $subchart"
  if [ -d "$subchart" ]; then
    yq e -i ".version = \"$ROOT_VERSION\"" "$subchart/Chart.yaml"
    echo "Updated version of subchart $subchart to $ROOT_VERSION"
  fi
done

# Rebuild Helm dependencies
echo "Rebuilding Helm dependencies"
helm dependency build "$CHART_PATH"

echo "All subchart versions have been aligned to version $ROOT_VERSION and dependencies updated"
