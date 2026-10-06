# Demo schema mirrors lightning/msg/VehiclePose; production uses the actual lightning type.
std_msgs/Header header

float64 x       # m
float64 y       # m
float64 z       # m

float64 roll    # deg
float64 pitch   # deg
float64 yaw     # deg

float64 speed   # m/s, signed vehicle speed
