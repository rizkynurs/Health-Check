# Bash Scripting: Server Health Check

This repository contains a Bash script `health_check.sh` that performs:
- **Ping Test** — verifies connectivity; exits non‑zero with **"Server unreachable"** if it fails.
- **HTTP/S Check** — uses `curl` to verify a web service on a specified port (default **80**); reports **UP**/**DOWN**.
- **Disk Usage** — prints the root filesystem (`/`) usage in a human‑readable percentage.
- All results are logged to **`health_check.log`** with timestamps.

## Prerequisites
Make sure the following packages are installed on your server:

- `ping`
- `curl`
- `df`
- `awk`

If any of them are missing, install with the following commands:

**On Ubuntu/Debian:**
```bash
sudo apt-get update && sudo apt-get install -y iputils-ping curl coreutils gawk
```

**On CentOS/RHEL:**
```bash
sudo yum install -y iputils curl coreutils gawk
```

---

## Diagram (Flow)

```mermaid
flowchart TD
  A[Start] --> B{Args OK?}
  B -- no --> C[Print usage & exit 2]
  B -- yes --> D[Ping server]
  D -- fail --> E[Log + 'Server unreachable' & exit 1]
  D -- success --> F[HTTP/S check via curl]
  F -- up --> G[Log 'UP']
  F -- down --> H[Log 'DOWN']
  G --> I[Disk usage of /]
  H --> I[Disk usage of /]
  I --> J[Append timestamped logs -> health_check.log]
  J --> K[Print results summary]
```

---

## Usage

```bash
git clone https://github.com/rizkynurs/Health-Check.git
chmod +x health_check.sh

# Default port 80
./health_check.sh localhost

# Custom port (e.g., 443 uses HTTPS automatically)
./health_check.sh example.com 443
```

**Example output:**
```
Server is reachable.
Web service on port 80 is UP.
Disk usage on / is 55%.
Results logged to health_check.log
```

> Note: Actual disk percentage will vary. If ping fails, the script prints **"Server unreachable"** and exits with a non‑zero status.

---
