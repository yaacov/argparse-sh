#!/usr/bin/env bash
# Build Fedora 44 images (system Bash + Bash 3.2) and run the test suite in each.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

IMAGE_BASH5="argparse-sh:fedora44"
IMAGE_BASH3_BASE="argparse-sh:fedora44-bash3-base"
IMAGE_BASH3="argparse-sh:fedora44-bash3"

if ! command -v docker >/dev/null 2>&1; then
    echo "Error: docker is required to run tests" >&2
    exit 1
fi

echo "=== Building $IMAGE_BASH5 ==="
docker build -f tests/Dockerfile.fedora44 -t "$IMAGE_BASH5" .

echo
if docker image inspect "$IMAGE_BASH3_BASE" >/dev/null 2>&1; then
    echo "=== Reusing existing $IMAGE_BASH3_BASE (Bash 3.2 already built) ==="
    echo "    To force rebuild: docker build --no-cache -f tests/Dockerfile.fedora44-bash3-base -t $IMAGE_BASH3_BASE ."
else
    echo "=== Building $IMAGE_BASH3_BASE (compiles Bash 3.2 once; reused on later runs) ==="
    docker build -f tests/Dockerfile.fedora44-bash3-base -t "$IMAGE_BASH3_BASE" .
fi

echo
echo "=== Building $IMAGE_BASH3 (thin runner on base) ==="
docker build -f tests/Dockerfile.fedora44-bash3 -t "$IMAGE_BASH3" .

run_suite() {
    local image=$1
    local label=$2
    echo
    echo "=== Running suite: $label ($image) ==="
    docker run --rm -v "$ROOT:/work" -w /work "$image"
}

run_suite "$IMAGE_BASH5" "Fedora 44 system Bash"
run_suite "$IMAGE_BASH3" "Fedora 44 Bash 3.2"

echo
echo "=== All Docker test suites passed ==="
