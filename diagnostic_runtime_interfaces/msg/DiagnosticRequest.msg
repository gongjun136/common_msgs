string READ_ACTIVE=READ_ACTIVE
string READ_HISTORY=READ_HISTORY
string CLEAR=CLEAR
string READ_SNAPSHOT=READ_SNAPSHOT
string schema_version
# Both IDs required, <=64 characters. The authenticated MQTT bridge owns client_id.
string client_id
string request_id
string operation
# 0 = all for READ_ACTIVE/READ_HISTORY; a concrete DTC required for CLEAR/READ_SNAPSHOT.
uint32 dtc
# READ_HISTORY only: ascending durable row cursor, page size 1..100 (0 = 50).
uint64 after_id
uint64 through_id
uint32 limit
