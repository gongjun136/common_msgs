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
