# Lighty SDNR Lite

Lightweight SDN-R (Software Defined Networking - Radio) based on [lighty.io](https://lighty.io/) for RAN Configuration Management.

## Features

- NETCONF Southbound for RAN device management
- RESTCONF Northbound API
- IETF NETCONF revision 2013-09-29 support (for O-RAN compatibility)
- Patched `NetconfMessageTransformer` for correct base RPC handling

## Prerequisites

- **JDK 17 or 21**
- **Maven 3.8+**
- **NETCONF model artifacts** (`6.0.6-SNAPSHOT`) in Maven repository
  - Built from [netconf-6.0.6-ios-mcn](https://github.com/ios-mcn-smo/netconf) via GitHub Actions

## Quick Build

### Linux/Mac

```bash
chmod +x build-app.sh

# Build app only
./build-app.sh

# Build app + Docker image
./build-app.sh --docker

# Clean build
./build-app.sh --clean
```

### Windows

```cmd
build-app.bat

# With Docker
build-app.bat --docker
```

### Manual Maven Build

```bash
# Build modules (includes netconf-transformer-patch)
mvn clean install -f modules/pom.xml -s build-settings.xml -DskipTests

# Build application
mvn clean install -f applications/pom.xml -s build-settings.xml -DskipTests

# Build Docker (optional)
cd applications/lighty-sdnr-lite/lighty-sdnr-lite-docker
mvn package docker:build -s ../../../build-settings.xml -DskipTests
```

## Running

### JAR

```bash
java -jar applications/lighty-sdnr-lite/lighty-sdnr-lite-app/target/lighty-sdnr-lite-app-0.0.1-SNAPSHOT.jar
```

### Docker

```bash
docker run -p 8181:8181 -p 8888:8888 <image-name>
```

## Project Structure

```
lighty-sdnr-lite-main/
├── modules/
│   ├── netconf-transformer-patch/   # Patched NetconfMessageTransformer
│   ├── iosmcn-pnf-registration/     # PNF registration module
│   ├── yang-schema/                  # YANG schema module
│   └── iosmcn-data-provider/        # Data provider module
├── applications/
│   └── lighty-sdnr-lite/
│       ├── lighty-sdnr-lite-app/    # Main application
│       └── lighty-sdnr-lite-docker/ # Docker build
├── build-app.sh                      # Linux build script
├── build-app.bat                     # Windows build script
└── build-settings.xml                # Maven settings with ODL repos
```

## Key Component: netconf-transformer-patch

This module provides a patched version of `NetconfMessageTransformer` from ODL netconf 10.0.2 that fixes `DatabindContext` usage for base RPCs (get-config, lock, etc.).

**The fix:** When handling base NETCONF RPCs, uses `baseSchema.databind()` instead of the device's `databind`, preventing schema context mismatches with devices that have different YANG model revisions.

## Dependencies

| Dependency | Version | Source |
|------------|---------|--------|
| Lighty.io | 23.0.0 | [PANTHEON.tech](https://lighty.io/) |
| ODL NETCONF | 10.0.2 | Via Lighty |
| NETCONF Models | 6.0.6-SNAPSHOT | [ios-mcn-smo/netconf](https://github.com/ios-mcn-smo/netconf) |

## License

Eclipse Public License 1.0
