#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Installing Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
fi

export PATH="$HOME/flutter/bin:$PATH"
flutter --version
flutter precache --web


if [ ! -f .env ]; then
  cat > .env <<'EOF'
API_BASE_URL=${API_BASE_URL:-https://.com}
EOF
fi

flutter pub get
flutter build web --release
