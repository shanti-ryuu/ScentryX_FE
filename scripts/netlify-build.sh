#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Installing Flutter SDK..."
  # Use a specific Flutter version
  FLUTTER_VERSION="3.13.9"
  FLUTTER_ARCHIVE="flutter_linux_${FLUTTER_VERSION}-stable_linux-x64.tar.xz"
  
  # Download and extract Flutter
  wget -q "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/$FLUTTER_ARCHIVE"
  tar -xf "$FLUTTER_ARCHIVE" -C "$HOME"
  export PATH="$HOME/flutter/bin:$PATH"
  flutter --version
fi

# Enable Flutter web
flutter config --enable-web

# Create .env file
cat > .env <<EOF
API_BASE_URL=https://scentryx-backend.onrender.com/api
FIREBASE_PROJECT_ID=scentryx-13554
EOF

# Get dependencies and build
flutter pub get
flutter build web --release --no-tree-shake-icons