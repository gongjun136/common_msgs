# common_msgs

Shared ROS 2 message and service packages used by Lightning localization,
Livox LiDAR integration, and vehicle-side applications.

## Repository layout

- `cgi430_interfaces/`: CGI-430 typed CAN and driver-status messages; used by the driver and localization.
- `livox_ros_driver/`: package `livox_ros_driver2`; Livox message definitions only.
- `diagnostic_monitor_interfaces/`: functional-safety heartbeat interfaces.
- `diagnostic_runtime_interfaces/`: diagnostic requests, state, progress, and DTC messages.
- `driving_evaluation_interfaces/`: vehicle pose, tracking error, and diagnostic performance messages.
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

## Company main synchronization (2026-10-06)

The company main interfaces are integrated while retaining `cgi430_interfaces`.
`CurrentGear` is now provided by `geosun_msgs`; the old
`domain_vcu_can_bridge` interface package was removed upstream.
Several existing CAN messages, including `SpeThrCAN4`, now include a
`diagnostic_monitor_interfaces/TopicCommHeader comm_header` field.
Publishers and subscribers must rebuild against the same interface version;
old serialized bag compatibility has not been validated by this synchronization.
The additional company `dev` and `main-toplevel` changes are not included here.
