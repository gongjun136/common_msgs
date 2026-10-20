uint8 UNKNOWN=0
uint8 USABLE=1
uint8 UNUSABLE=2
# 0=front, 1=rear, 2=left, 3=right
uint8 role
diagnostic_monitor_interfaces/TopicCommHeader comm_header
uint64 boot_id
string config_version
uint8 usability
# Eleven source-owned HMS categories; no system lifecycle fields.
diagnostic_monitor_interfaces/DtcObservation[] observations
# Independent bounded-warning evidence, default false for old/unverified sources.
# Does not clear observations. Requires advancing PTP, <=1 ms offset,
# no detected clock jump, and only allowlisted native warning severity.
bool bounded_time_sync_warning
int64 time_sync_offset_ns
# Steady-clock age of the last qualifying advancing synchronization sample.
uint64 time_sync_evidence_age_us
