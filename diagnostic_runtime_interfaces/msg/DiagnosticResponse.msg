string schema_version
string client_id
string request_id
string operation
uint64 engine_boot_id
uint64 generated_at_us
bool success
string error_code
string message
# Operation-specific JSON object. Bridge parses this into an object for MQTT.
string data_json
