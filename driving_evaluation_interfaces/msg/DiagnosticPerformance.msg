# Stamp is the ROS publication time of this snapshot; frame_id is empty by default.
std_msgs/Header header
# Parallel arrays, one entry per occurrence in the current phase.
# Default codes: 1=pause, 2=speed_abnormal, 3=trajectory_deviation.
# Duration is in seconds, including confirmation time. No phase identity on wire.
int32[] alarm_num
float64[] alarm_time
