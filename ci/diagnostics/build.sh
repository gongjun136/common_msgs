#!/usr/bin/env bash
# Build only the three diagnostics interface packages; leave other owners' packages alone.
set -eo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
mode="${1:-native}"
packages=(diagnostic_monitor_interfaces diagnostic_runtime_interfaces driving_evaluation_interfaces)
if [[ "$mode" == native ]]; then
  source /opt/ros/humble/setup.bash
  out="${DIAG_MESSAGE_OUT:-$root/.work/diagnostics/native}"
  mkdir -p "$out"
  cd "$out"
  colcon --log-base "$out/log" build --base-paths "$root" \
    --build-base "$out/build" --install-base "$out/install" \
    --packages-select "${packages[@]}" --executor sequential \
    --cmake-args -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=Release \
    --event-handlers console_cohesion+ 2>&1 | tee "$out/build.log"
elif [[ "$mode" == cross ]]; then
  image="${2:?Usage: build.sh cross IMAGE_ID_OR_DIGEST}"
  out="${DIAG_MESSAGE_OUT:-$root/.work/diagnostics/aarch64}"
  mkdir -p "$out"
  out="$(cd "$out" && pwd)"
  docker run --rm --network none --cpus 4 --memory 8g \
    --user "$(id -u):$(id -g)" -e HOME=/tmp -e BUILD_ARCH=aarch64 \
    -e PYTHONPATH=/usr/lib/python3/dist-packages \
    -e CMAKE_BUILD_PARALLEL_LEVEL=2 -e MAKEFLAGS=-j2 \
    --mount "type=bind,src=$root,dst=/workspace/messages,readonly" \
    --mount "type=bind,src=$out,dst=/workspace/out" \
    "$image" bash -c 'set -eo pipefail
      source /opt/ros/humble/setup.bash
      cd /workspace/out
      colcon --log-base /workspace/out/log build \
        --base-paths /workspace/messages --build-base /workspace/out/build --install-base /workspace/out/install \
        --packages-select diagnostic_monitor_interfaces diagnostic_runtime_interfaces driving_evaluation_interfaces \
        --executor sequential --cmake-args -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE=/workspace/messages/ci/diagnostics/aarch64.cmake \
        --event-handlers console_cohesion+' 2>&1 | tee "$out/build.log"
else
  echo 'Usage: build.sh native | cross IMAGE_ID_OR_DIGEST' >&2
  exit 2
fi
