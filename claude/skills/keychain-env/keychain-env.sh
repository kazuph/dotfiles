#!/usr/bin/env bash
# Usage: scripts/keychain-env.sh keychain-env/<mapping>.env <command> [args...]
# mapping file format (one per line): ENV_VAR=KeychainServiceName
# Lines starting with # or blank lines are ignored.
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <mapping-file> <command> [args...]" >&2
  exit 64
fi

MAPPING_FILE="$1"
shift

if [[ ! -f "$MAPPING_FILE" ]]; then
  echo "Mapping file not found: $MAPPING_FILE" >&2
  exit 66
fi

CURRENT_USER="${LOGNAME:-${USER}}"

while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  if [[ "$line" != *=* ]]; then
    echo "Invalid line in mapping file: $line" >&2
    exit 65
  fi
  VAR_NAME="${line%%=*}"
  SERVICE_NAME="${line#*=}"
  if [[ -z "$VAR_NAME" || -z "$SERVICE_NAME" ]]; then
    echo "Invalid mapping entry: $line" >&2
    exit 65
  fi
  SECRET_VALUE=$(security find-generic-password -a "$CURRENT_USER" -s "$SERVICE_NAME" -w)
  export "$VAR_NAME=$SECRET_VALUE"
done < "$MAPPING_FILE"

exec "$@"
