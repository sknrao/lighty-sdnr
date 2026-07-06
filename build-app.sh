#!/bin/bash
# Build script for Lighty SDNR application
#
# This project is SELF-CONTAINED - no external netconf repo needed!
# O-RAN NETCONF support is built-in via:
#   - oran-netconf-model: YANG model with 2013-09-29 revision
#   - netconf-transformer-patch: Fix for base RPC parsing
#
# Prerequisites:
#   - JDK 17 or 21
#   - Maven 3.8+
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
            echo "This project is SELF-CONTAINED - no external netconf repo needed!"
            echo "O-RAN NETCONF support is built-in."
            exit 0
            ;;
    esac
done

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lighty SDNR App Build Script${NC}"
echo -e "${CYAN}  (Self-contained O-RAN NETCONF)${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}[1/4] Checking prerequisites...${NC}"

if ! command -v java &> /dev/null; then
    echo -e "${RED}  ERROR: Java not found. Please install JDK 17 or 21.${NC}"
    exit 1
fi
JAVA_VERSION=$(java -version 2>&1 | head -n 1)
echo -e "${GREEN}  Java: OK ($JAVA_VERSION)${NC}"

if ! command -v mvn &> /dev/null; then
    echo -e "${RED}  ERROR: Maven not found. Please install Maven 3.8+.${NC}"
    exit 1
fi
MVN_VERSION=$(mvn -version 2>&1 | head -n 1)
echo -e "${GREEN}  Maven: OK ($MVN_VERSION)${NC}"

# Check if settings file exists, use default if not
if [ -f "$SETTINGS_FILE" ]; then
    echo -e "${GREEN}  Settings: $SETTINGS_FILE${NC}"
    SETTINGS_OPT="-s $SETTINGS_FILE"
else
    echo -e "${YELLOW}  Settings: Using default Maven settings${NC}"
    SETTINGS_OPT=""
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

echo -e "  Building modules (oran-netconf-model, netconf-transformer-patch, etc.)..."
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
    echo "  - Docker image: iosmcn-sdnrlite:latest"
fi
echo ""
echo "O-RAN NETCONF Support (self-contained):"
echo "  - IETF NETCONF 2013-09-29 revision with NACM"
echo "  - NetconfMessageTransformer fix for base RPC parsing"
echo ""
echo "To run:"
echo "  java -jar applications/lighty-sdnr-lite/lighty-sdnr-lite-app/target/lighty-sdnr-lite-app-0.0.1-SNAPSHOT.jar"
echo ""
