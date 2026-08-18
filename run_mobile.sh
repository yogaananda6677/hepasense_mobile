#!/usr/bin/env bash
# =============================================================================
# 📱 HEPASENSE MOBILE RUN HELPER SCRIPT
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[INFO] Creating .env file from .env.example..."
  cp "$SCRIPT_DIR/.env.example" "$ENV_FILE"
fi

DEVICE_ID="${1:-}"

if [[ -z "$DEVICE_ID" ]]; then
  echo "[INFO] Detecting available Flutter devices..."
  flutter devices
  echo ""
  echo "Usage: ./run_mobile.sh [device_id]"
  echo "Example: ./run_mobile.sh 133157049Y020881"
  exit 0
fi

echo "=================================================================="
echo "🚀 Running HepaSense Mobile App on device $DEVICE_ID"
echo "   Reading configuration from .env..."
echo "=================================================================="

flutter run -d "$DEVICE_ID" --dart-define-from-file="$ENV_FILE"
