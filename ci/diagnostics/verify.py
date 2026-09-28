#!/usr/bin/env python3
"""Build verification only; no vehicle-side Python component."""
import argparse
import importlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
PACKAGES = ("diagnostic_monitor_interfaces", "diagnostic_runtime_interfaces", "driving_evaluation_interfaces")

def verify(mode, install):
    messages = []
    for package in PACKAGES:
        for definition in sorted((ROOT / package / "msg").glob("*.msg")):
            stem = re.sub(r"(?<!^)(?=[A-Z])", "_", definition.stem).lower()
            headers = list((install / package / "include").rglob(stem + ".hpp"))
            if not headers:
                raise AssertionError(f"Missing generated C++ header: {package}/{definition.stem}")
            if mode == "native":
                from rclpy.serialization import serialize_message, deserialize_message
                cls = getattr(importlib.import_module(package + ".msg"), definition.stem)
                value = cls()
                if definition.stem == "NodeHeartbeat":
                    value.node_id = 11; value.boot_id = 123; value.heartbeat_seq = 4294967295; value.work_seq = 7; value.state = 3
                if definition.stem == "TopicCommHeader":
                    value.source_id = 11; value.seq = 4294967295; value.stamp_us = 1700000000000000
                assert deserialize_message(serialize_message(value), cls) == value
            messages.append(package + "/msg/" + definition.stem)
    expected = 183 if mode == "aarch64" else 62
    elf = []
    for path in sorted(install.rglob("*")):
        if not path.is_file():
            continue
        with path.open("rb") as f:
            header = f.read(20)
        if header[:4] == b"\x7fELF":
            assert header[4:6] == b"\x02\x01", str(path)
            assert int.from_bytes(header[18:20], "little") == expected, str(path)
            elf.append(str(path.relative_to(install)))
    assert len(messages) == 14 and elf
    for package in PACKAGES:
        assert any(p.startswith(package + "/") and "typesupport_cpp" in p for p in elf), package
    return dict(passed=True, architecture=mode, messages=messages, message_count=len(messages), elf_count=len(elf),
                serialization_roundtrip=(mode == "native"), target_execution_verified=False,
                scope="Only the three diagnostics interface packages; other common packages/Jenkins pipeline not covered.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["native", "aarch64"])
    parser.add_argument("install", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    result = json.dumps(verify(args.mode, args.install.resolve()), indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(result)
    print(result)
