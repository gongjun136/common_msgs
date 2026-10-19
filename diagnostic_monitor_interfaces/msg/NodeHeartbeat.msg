# Fixed logical node ID. Zero is invalid.
uint16 node_id

# Non-zero per-process boot ID. Constant for the process lifetime.
uint64 boot_id

# Incremented for each heartbeat publication; wraps naturally.
uint32 heartbeat_seq

# Incremented only when the selected real business work completes.
uint32 work_seq

# 0=not ready, 1=idle, 2=running, 3=degraded, 4=fault.
# The diagnostic engine treats state 3 and 4 as node-state abnormalities.
uint8 state

# Complete current active DTC set for this node, not an incremental update.
# [] means no active self-reported faults; never include 0 or historical codes.
# Use only DTCs assigned to this node by the diagnostic configuration.
# Engine confirms after 1 s present and recovers after 2 s absent in valid heartbeats.
uint32[] active_fault
