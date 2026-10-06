uint64 engine_boot_id
uint64 revision
string config_version
string config_hash
uint64 generated_monotonic_ns
# Infrastructure readiness, not a motion enable and not "no faults".
bool ready
bool coverage_complete
string storage_status
string medkit_status
uint64 input_errors
uint64 max_tick_gap_ms
DtcState[] faults
