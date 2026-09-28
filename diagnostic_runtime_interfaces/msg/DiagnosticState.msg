# Module health, NOT vehicle operating mode or motion authorization.
uint8 NOT_READY=0
uint8 IDLE=1
uint8 RUNNING=2
uint8 DEGRADED=3
uint8 FAULT=4
uint8 state
string schema_version
uint64 engine_boot_id
uint64 publish_seq
uint64 revision
uint64 generated_at_us
string config_version
string config_hash
# False means an empty active_faults list MUST NOT be interpreted as all-clear.
bool faults_valid
bool coverage_complete
string storage_status
string medkit_status
string reason
# Full current set, including recovered-but-still-latched faults. Never a delta.
DtcState[] active_faults
