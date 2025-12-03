#!/usr/bin/env bash
set -euo pipefail

# Check if Flutter is installed, if not, use Flutter from cache
if ! command -v flutter >/dev/null 2>&1; then
  echo "Installing Flutter SDK..."
  # Use a specific version that we know works
  FLUTTER_VERSION="3.13.9"  # Using a stable version
  FLUTTER_ZIP="flutter_linux_${FLUTTER_VERSION}-stable_$TARGETARCH.tar.xz"
  
  # Download and extract Flutter
  wget -q "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/$FLUTTER_ZIP"
  tar -xf "$FLUTTER_ZIP" -C "$HOME"
  export PATH="$HOME/flutter/bin:$PATH"
  flutter --version
fi

# Enable Flutter web
flutter config --enable-web

# Create .env file
cat > .env <<EOF
API_BASE_URL=${API_BASE_URL:-https://scentryx-backend.onrender.com}
FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID:-scentryx-13554}
EOF

# Get dependencies and build
flutter pub get
flutter build web --release --no-tree-shake-icons