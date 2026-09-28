# Lifecycle transition stream. Use snapshot for current state, SQLite for history.
uint64 engine_boot_id
uint64 event_seq
string config_version
string config_hash
uint64 generated_monotonic_ns
DtcState fault
