cmake_minimum_required(VERSION 3.8)
project(cgi430_interfaces)

if(DEFINED CGI430_CPU_PROFILE)
  message(STATUS
    "CGI-430 CPU profile is applied by cgi430_driver: ${CGI430_CPU_PROFILE}")
endif()

find_package(ament_cmake REQUIRED)
find_package(rosidl_default_generators REQUIRED)
find_package(std_msgs REQUIRED)

rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/CanFrame.msg"
  "msg/GpsTime.msg"
  "msg/ImuAngularRate.msg"
  "msg/ImuAcceleration.msg"
  "msg/InsStatus.msg"
  "msg/Altitude.msg"
  "msg/PositionSigma.msg"
  "msg/EarthVelocity.msg"
  "msg/VelocitySigma.msg"
  "msg/VehicleAcceleration.msg"
  "msg/Attitude.msg"
  "msg/AttitudeSigma.msg"
  "msg/VehicleAngularRate.msg"
  "msg/Longitude.msg"
  "msg/Latitude.msg"
  "msg/DriverStatus.msg"
  DEPENDENCIES std_msgs
)

ament_export_dependencies(rosidl_default_runtime)
ament_package()
