# Source condition only. Confirmation, latching and recovery belong to the consumer.
uint8 UNKNOWN=0
uint8 PASS=1
uint8 FAIL=2
uint32 dtc
uint8 physical_condition
# Advances for a completed check, not for retransmission of a cached result.
uint32 evaluation_seq
# Steady-clock age of that check; UINT64_MAX means never evaluated.
uint64 evaluation_age_us
