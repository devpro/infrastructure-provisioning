# Infrastructure provisioning

Work in progress (initiated in March 2024, last updated October 2025)

## Quick start

Download and source the files:

```bash
curl -sfL https://raw.githubusercontent.com/devpro/infrastructure-provisioning/develop/scripts/download.sh | sh -s -- -o temp
. temp/scripts/index.sh
```

Call a function:

```bash
k3s_create_cluster v1.23
```

## Going further

Browse the [catalog of functions](scripts/README.md#shell-functions) and [concrete examples](scripts/README.md#concrete-examples).
