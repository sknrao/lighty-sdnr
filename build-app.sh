#!/bin/bash
# Build script for Lighty SDNR application
#
# Prerequisites:
#   - JDK 17 or 21
#   - Maven 3.8+
#   - NETCONF 10.0.x artifacts (10.0.4-SNAPSHOT) already in Maven repo
#     Built from: netconf-10.0.x/ (contains O-RAN NETCONF 2013 fixes)
#
# Usage:
#   ./build-app.sh              # Build app only
#   ./build-app.sh --docker     # Build app + Docker image
#   ./build-app.sh --clean      # Clean build

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_FILE="$SCRIPT_DIR/build-settings.xml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse arguments
BUILD_DOCKER=false
CLEAN_BUILD=false

for arg in "$@"; do
    case $arg in
        --docker)
            BUILD_DOCKER=true
            ;;
        --clean)
            CLEAN_BUILD=true
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --docker   Include Docker image build"
            echo "  --clean    Clean build (remove target directories)"
            echo "  --help     Show this help message"
            echo ""
            echo "Note: Requires NETCONF 10.0.x artifacts (10.0.4-SNAPSHOT) to be"
            echo "      already installed in your local Maven repository."
            echo "      Build with: cd ../netconf-10.0.x && mvn install -DskipTests -pl artifacts,bnd-parent,parent,model/rfc6241,plugins/netconf-client-mdsal -am"
            exit 0
            ;;
    esac
done

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lighty SDNR App Build Script${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}[1/4] Checking prerequisites...${NC}"

if ! command -v java &> /dev/null; then
    echo -e "${RED}  ERROR: Java not found. Please install JDK 17 or 21.${NC}"
    exit 1
fi
echo -e "${GREEN}  Java: OK${NC}"

if ! command -v mvn &> /dev/null; then
    echo -e "${RED}  ERROR: Maven not found. Please install Maven 3.8+.${NC}"
    exit 1
fi
echo -e "${GREEN}  Maven: OK${NC}"

# Check if settings file exists, use default if not
if [ -f "$SETTINGS_FILE" ]; then
    echo -e "${GREEN}  Settings: $SETTINGS_FILE${NC}"
    SETTINGS_OPT="-s $SETTINGS_FILE"
else
    echo -e "${YELLOW}  Settings: Using default Maven settings${NC}"
    SETTINGS_OPT=""
fi

# Check if netconf 10.0.x artifacts are available
RFC6241_PATH=~/.m2/repository/org/opendaylight/netconf/model/rfc6241/10.0.4-SNAPSHOT
TRANSFORMER_PATH=~/.m2/repository/org/opendaylight/netconf/netconf-client-mdsal/10.0.4-SNAPSHOT
ARTIFACTS_PATH=~/.m2/repository/org/opendaylight/netconf/netconf-artifacts/10.0.4-SNAPSHOT
if [ -d "$RFC6241_PATH" ] && [ -d "$TRANSFORMER_PATH" ] && [ -d "$ARTIFACTS_PATH" ]; then
    echo -e "${GREEN}  NETCONF 10.0.x artifacts: Found in Maven repo${NC}"
else
    echo -e "${RED}  WARNING: NETCONF 10.0.x artifacts not found in Maven repo${NC}"
    echo -e "${RED}           Build may fail. Build netconf-10.0.x first:${NC}"
    echo -e "${RED}           cd ../netconf-10.0.x && mvn install -DskipTests -pl artifacts,bnd-parent,parent,model/rfc6241,plugins/netconf-client-mdsal -am${NC}"
fi
echo ""

# Maven options
MVN_OPTS="-DskipTests"
if [ "$CLEAN_BUILD" = true ]; then
    MVN_CLEAN="clean"
else
    MVN_CLEAN=""
fi

# Build lighty modules
echo -e "${YELLOW}[2/4] Building Lighty modules...${NC}"

cd "$SCRIPT_DIR"

echo -e "  Building custom modules (pnf-registration, yang-schema, data-provider)..."
mvn $MVN_CLEAN install -f modules/pom.xml $SETTINGS_OPT $MVN_OPTS
echo -e "${GREEN}    Modules OK${NC}"
echo ""

# Build lighty app
echo -e "${YELLOW}[3/4] Building Lighty SDNR application...${NC}"

echo -e "  Building application JAR..."
mvn $MVN_CLEAN install -f applications/pom.xml $SETTINGS_OPT $MVN_OPTS
echo -e "${GREEN}    Application OK${NC}"
echo ""

# Docker build (optional)
if [ "$BUILD_DOCKER" = true ]; then
    echo -e "${YELLOW}[4/4] Building Docker image...${NC}"
    
    cd "$SCRIPT_DIR/applications/lighty-sdnr-lite/lighty-sdnr-lite-docker"
    mvn package docker:build $SETTINGS_OPT $MVN_OPTS
    echo -e "${GREEN}    Docker OK${NC}"
    cd "$SCRIPT_DIR"
    echo ""
else
    echo -e "${YELLOW}[4/4] Skipping Docker build (use --docker flag to include)${NC}"
    echo ""
fi

echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}  Build Complete!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo "Artifacts:"
echo "  - Lighty app JAR: applications/lighty-sdnr-lite/lighty-sdnr-lite-app/target/lighty-sdnr-lite-app-0.0.1-SNAPSHOT.jar"
if [ "$BUILD_DOCKER" = true ]; then
    echo "  - Docker image: Check 'docker images'"
fi
echo ""
echo "To run:"
echo "  java -jar applications/lighty-sdnr-lite/lighty-sdnr-lite-app/target/lighty-sdnr-lite-app-0.0.1-SNAPSHOT.jar"
echo ""
