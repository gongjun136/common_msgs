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
