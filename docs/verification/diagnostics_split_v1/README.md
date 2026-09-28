# Diagnostics interface migration V1 — 2026-09-28

- All three diagnostics interface packages build successfully on WSL Ubuntu 22.04 / ROS 2 Humble.
- All three cross-compile in the existing ARM64 SDK Docker image with `--network none`.
- All 14 message types have generated C++ headers; native serialization/deserialization round-trips pass.
- Native and target installs each contain 36 ELF files; machines are x86_64 and AArch64 respectively.
- Existing NodeHeartbeat/TopicCommHeader fields are unchanged; new runtime/evaluation packages preserve the old diagnostic workspace definitions.

See `native.json`, `aarch64.json`. Reproduce using `ci/diagnostics/build.sh` and `ci/diagnostics/verify.py`.
The runnable repository additionally builds the real consumers against these packages and records its integration results.
Only the three diagnostics packages are covered; other teams' packages, the shared Jenkins pipeline and target execution were not validated here.
These verification results were captured before the migration was committed or pushed.
