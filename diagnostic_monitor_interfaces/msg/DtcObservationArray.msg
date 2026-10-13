diagnostic_monitor_interfaces/TopicCommHeader comm_header
uint64 boot_id
uint32 interface_version
string config_version
# Complete source-owned DTC set, sorted by code. Absence never means recovery.
diagnostic_monitor_interfaces/DtcObservation[] observations
