# Lighty SDNR - O-RAN NETCONF Controller

A lightweight SDN controller based on [lighty.io](https://lighty.io/) with **O-RAN NETCONF support**.

## Features

- **RESTCONF Northbound** - RESTful API for network management
- **NETCONF Southbound** - Connect to NETCONF-enabled devices
- **O-RAN Compatibility** - IETF NETCONF 2013-09-29 revision with NACM extensions
- **Self-Contained** - No external dependencies to build

## O-RAN NETCONF Support

This project includes built-in support for O-RAN devices that require the IETF NETCONF 2013-09-29 revision:

| Module | Purpose |
|--------|---------|
| `oran-netconf-model` | YANG model with `ietf-netconf@2013-09-29` revision (includes NACM attributes) |
| `netconf-transformer-patch` | Fix for NetconfMessageTransformer to correctly parse base RPC responses |

These modules compile against Lighty 23.x bundled dependencies (netconf 10.0.2 from ODL Vanadium). **No external netconf repository is needed.**

## Quick Start

### Prerequisites

- JDK 21
- Maven 3.8+
- Docker (optional)

### Build

```bash
# Clone the repository
git clone https://github.com/sknrao/lighty-sdnr.git
cd lighty-sdnr

# Build
mvn clean install -DskipTests

# Or use the build script
./build-app.sh
```

### Run Locally

```bash
java -jar applications/lighty-sdnr-lite/lighty-sdnr-lite-app/target/lighty-sdnr-lite-app-0.0.1-SNAPSHOT.jar
```

### Run with Docker

```bash
# Build Docker image
./build-app.sh --docker

# Run container
docker run -d --name sdnr \
  -p 8181:8181 \
  -p 8888:8888 \
  iosmcn-sdnrlite:latest

# View logs
docker logs -f sdnr
```

### Pull Pre-built Image

```bash
docker pull ghcr.io/sknrao/lighty-sdnr:latest
docker run -d --name sdnr -p 8181:8181 -p 8888:8888 ghcr.io/sknrao/lighty-sdnr:latest
```

## API Endpoints

| Endpoint | Port | Description |
|----------|------|-------------|
| RESTCONF | 8888 | RESTful API for configuration and state |
| OpenAPI | 8888/openapi | API documentation |

### Example: Mount a NETCONF Device

```bash
curl -X PUT \
  http://localhost:8888/restconf/data/network-topology:network-topology/topology=topology-netconf/node=device1 \
  -H 'Content-Type: application/json' \
  -u admin:admin \
  -d '{
    "node": [{
      "node-id": "device1",
      "netconf-node-topology:host": "192.168.1.100",
      "netconf-node-topology:port": 830,
      "netconf-node-topology:username": "admin",
      "netconf-node-topology:password": "admin",
      "netconf-node-topology:tcp-only": false,
      "netconf-node-topology:keepalive-delay": 120
    }]
  }'
```

## Project Structure

```
lighty-sdnr/
├── modules/
│   ├── oran-netconf-model/        # O-RAN NETCONF 2013 YANG model
│   ├── netconf-transformer-patch/ # NetconfMessageTransformer fix
│   ├── iosmcn-pnf-registration/   # PNF registration module
│   ├── yang-schema/               # Custom YANG schemas
│   └── iosmcn-data-provider/      # Data provider module
├── applications/
│   └── lighty-sdnr-lite/
│       ├── lighty-sdnr-lite-app/    # Main application
│       └── lighty-sdnr-lite-docker/ # Docker packaging
└── build-app.sh                   # Build script
```

## Version Compatibility

| Component | Version |
|-----------|---------|
| Lighty.io | 23.0.0 |
| OpenDaylight | Vanadium |
| NETCONF | 10.0.2 (bundled with Lighty) |
| Java | 21 |

## Configuration

The application reads configuration from `lightyControllerConfig.json`. See the `config/` directory for examples.

## License

This project is licensed under the Eclipse Public License v1.0.

## Acknowledgments

- [lighty.io](https://lighty.io/) by PANTHEON.tech
- [OpenDaylight](https://www.opendaylight.org/)
