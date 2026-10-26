# Last SDK-confirmed identity, NOT an online/health indicator.
# stamp is zero until the first accepted SDK device-info callback.
std_msgs/Header header
string role
string ip
string serial_number
# Livox SDK device type code; zero before discovery.
uint8 device_type
# False means SN is unavailable/invalid; never substitute an IP or configured SN.
bool identity_valid
