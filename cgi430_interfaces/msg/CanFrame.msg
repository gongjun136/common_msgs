# Kernel receive timestamp and original CAN payload for traceability.
std_msgs/Header header
uint32 can_id
bool is_extended
uint8 dlc
uint8[8] data
bool valid
