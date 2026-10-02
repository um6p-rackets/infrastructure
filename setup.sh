#!/bin/bash
set -euo pipefail

FRONTEND="https://github.com/um6p-rackets/frontend.git"
BACKEND="https://github.com/um6p-rackets/backend.git"

cd "$(dirname "$0")/.."

[ -d frontend ] || git clone "$FRONTEND" frontend
[ -d backend ] || git clone "$BACKEND" backend