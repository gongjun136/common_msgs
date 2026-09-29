cmake_minimum_required(VERSION 3.8)
project(diagnostic_runtime_interfaces)
find_package(ament_cmake REQUIRED)
find_package(rosidl_default_generators REQUIRED)
rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/DtcState.msg" "msg/DtcSnapshot.msg" "msg/DtcEvent.msg" "msg/DiagnosticProgress.msg"
  "msg/DiagnosticState.msg" "msg/DiagnosticRequest.msg" "msg/DiagnosticResponse.msg")
ament_export_dependencies(rosidl_default_runtime)
ament_package()
