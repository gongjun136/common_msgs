# vcu publish /angle_sensor_topic message, cycle 100ms
diagnostic_monitor_interfaces/TopicCommHeader comm_header
std_msgs/Header header       # ROS standard message header

float64    x        # 车辆转向角度原始值 (0-5000)mV

