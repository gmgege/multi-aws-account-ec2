#!/usr/bin/env python3
import sys
import yaml
import json

if len(sys.argv) < 2:
    print(json.dumps({"failed": True, "error": "Missing config file argument"}))
    sys.exit(1)

config_file = sys.argv[1]

try:
    with open(config_file, "r") as f:
        config = yaml.safe_load(f)
    # 输出accounts为JSON字符串，兼容Terraform external data source
    print(json.dumps({"accounts": json.dumps(config["accounts"])}))
except Exception as e:
    print(json.dumps({"failed": True, "error": str(e)}))
    sys.exit(1)
