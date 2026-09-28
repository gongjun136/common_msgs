# common_msgs

Shared ROS 2 message and service packages used by Lightning localization,
Livox LiDAR integration, and vehicle-side applications.

## Repository layout

- `livox_ros_driver/`: package `livox_ros_driver2`; Livox message definitions only.
- `diagnostic_monitor_interfaces/`: functional-safety heartbeat interfaces.
- `lightning_interfaces/`: Lightning localization interfaces.
- Other directories contain shared project-specific interfaces.

This repository contains interfaces only. Driver and algorithm implementations
must depend on these packages instead of embedding duplicate message definitions.

## Workspace import

This repository is normally imported beside its consumers with a `.repos` file:

```bash
vcs import src < src/<consumer-repository>/common_msgs.repos
```

Each ROS package name must appear only once in a colcon workspace.

## Diagnostics interfaces (migration V1)

The diagnostics packages are authoritative here; do not also import their old copies
from the former monolithic diagnostics workspace. Existing package/type names and
field layouts are preserved. NodeHeartbeat and TopicCommHeader are wire-compatible
with the previously checked-in versions; MonitoredSample is added for isolated mocks.

| Package | Messages | Purpose |
| --- | ---: | --- |
| diagnostic_monitor_interfaces | 3 | Heartbeat, communication header, bench-only sample |
| diagnostic_runtime_interfaces | 7 | Diagnostic state, request/response, DTC records |
| driving_evaluation_interfaces | 4 | Driving evaluation input/output |

`NodeHeartbeat.state`: 0=not ready, 1=idle, 2=running, 3=degraded, 4=fault.
State 3/4 is classified by the diagnostic policy as a node-state abnormality.
`MonitoredSample` is for bench tests, not a replacement for production actuator messages.
Upstream `ros2_medkit_msgs` stays with the pinned Medkit source in the runnable repo.

Build the diagnostics interfaces on Ubuntu 22.04 / ROS 2 Humble:

```bash
bash ci/diagnostics/build.sh native
# Use the team's mixed x86 tools / ARM64 sysroot SDK, not an arbitrary ARM container:
bash ci/diagnostics/build.sh cross <local-image-id-or-digest>
```

Outputs: `.work/diagnostics/native` and `.work/diagnostics/aarch64`.
The cross build runs with network disabled. This validates the three diagnostics
packages, not all other teams' interface packages or their Jenkins pipeline.
The existing Jenkinsfile and ci/Dockerfile are preserved.
Consumers must build against these source packages or the matching target-architecture
installation; copying only `.msg` files to a target does not provide runtime type support.

Verification after building:

```bash
source /opt/ros/humble/setup.bash
source .work/diagnostics/native/install/local_setup.bash
python3 ci/diagnostics/verify.py native .work/diagnostics/native/install
python3 ci/diagnostics/verify.py aarch64 .work/diagnostics/aarch64/install
```

Migration V1 results: `docs/verification/diagnostics_split_v1/`.
