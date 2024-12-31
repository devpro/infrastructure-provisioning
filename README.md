# Infrastructure provisioning

Work in progress (initiated in March 2024, last updated December 2024)

## Getting started

### Bash scripting

Download and source the files (targetting `develop` branch in this example):

```bash
curl -sfL https://raw.githubusercontent.com/devpro/infrastructure-provisioning/develop/scripts/download.sh | sh -s -- -o temp
. temp/scripts/index.sh
```

Call a function:

```bash
k3s_create_cluster v1.23
```

Browse the [catalog of functions](scripts/README.md#shell-functions) and [concrete examples](scripts/README.md#concrete-examples).
