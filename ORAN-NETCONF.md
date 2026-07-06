# O-RAN NETCONF Support

This document describes the O-RAN NETCONF enhancements in this project.

## Background

Some O-RAN devices implement IETF NETCONF with the **2013-09-29 revision** (RFC 6241 + RFC 6536 NACM extensions), rather than the standard 2011-06-01 revision. This causes compatibility issues with standard OpenDaylight NETCONF implementations.

## Solution

This project provides **self-contained** O-RAN NETCONF support through two modules:

### 1. `oran-netconf-model`

Contains the `ietf-netconf@2013-09-29.yang` YANG model which includes:
- All standard NETCONF operations (get, get-config, edit-config, etc.)
- NACM (Network Access Control Model) extension attributes:
  - `nacm:default-deny-all` on sensitive operations like `delete-config` and `kill-session`

This generates Java binding classes that can handle NETCONF responses with NACM attributes.

### 2. `netconf-transformer-patch`

Fixes an issue in `NetconfMessageTransformer` where base NETCONF RPC responses (get-config, lock, unlock, etc.) were parsed using the device's schema context instead of the base NETCONF schema.

**The Fix:**
```java
// Before (incorrect): Used device databind for all responses
final var result = databind.toNormalizedNode(...);

// After (correct): Use baseSchema databind for base NETCONF RPCs
final var effectiveDatabind = needToUseBaseCtxForResult ? baseSchema.databind() : databind;
final var result = effectiveDatabind.toNormalizedNode(...);
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Lighty 23.x                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              lighty-netconf-sb                       │   │
│  │         (bundles netconf 10.0.2 from ODL)           │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ uses
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Your Application                          │
│  ┌───────────────────────┐  ┌───────────────────────────┐  │
│  │  oran-netconf-model   │  │ netconf-transformer-patch │  │
│  │  (2013 YANG model)    │  │ (1 Java class fix)        │  │
│  │                       │  │                           │  │
│  │  Compiles against     │  │  Compiles against         │  │
│  │  mdsal 15.0.4         │  │  netconf 10.0.2           │  │
│  └───────────────────────┘  └───────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Why Self-Contained?

Previous approaches required building and maintaining a forked netconf repository. This had several issues:
- Complex build process with selective module builds
- Version conflicts when mixing custom netconf with Lighty's bundled version
- Runtime ClassNotFoundException errors due to mismatched model revisions

The self-contained approach:
- **No external netconf repo needed** - everything builds in one project
- **No version conflicts** - compiles against Lighty's exact dependency versions
- **Simple build** - just `mvn clean install`
- **Easy maintenance** - only two small modules to maintain

## Files

```
modules/
├── oran-netconf-model/
│   ├── pom.xml
│   └── src/main/yang/
│       └── ietf-netconf@2013-09-29.yang    # The 2013 revision YANG
│
└── netconf-transformer-patch/
    ├── pom.xml
    └── src/main/java/.../impl/
        └── NetconfMessageTransformer.java   # Patched transformer
```

## Dependencies Used

| Dependency | Version | Source |
|------------|---------|--------|
| mdsal binding-parent | 15.0.4 | ODL Nexus |
| yangtools | 14.0.20 | ODL Nexus |
| netconf-client-mdsal | 10.0.2 | Bundled with Lighty |
| rfc8341 (NACM) | from mdsal | ODL Nexus |

All dependencies are published artifacts from OpenDaylight - no custom builds required.

## Testing O-RAN Compatibility

To verify O-RAN NETCONF support is working:

1. Mount an O-RAN device via RESTCONF
2. Check the device connection status
3. Perform get-config operations
4. Verify NACM-attributed responses are parsed correctly

```bash
# Mount device
curl -X PUT http://localhost:8888/restconf/data/network-topology:network-topology/topology=topology-netconf/node=oran-device ...

# Check status
curl http://localhost:8888/restconf/data/network-topology:network-topology/topology=topology-netconf/node=oran-device/netconf-node-topology:connection-status
```
