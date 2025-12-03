#!/usr/bin/env bash
set -euxo pipefail

echo "Starting build process..."
echo "Current directory: $(pwd)"
echo "Node version: $(node --version)"
echo "NPM version: $(npm --version)"

# Set up Flutter
if ! command -v flutter >/dev/null 2>&1; then
  echo "Installing Flutter SDK..."
  FLUTTER_VERSION="3.16.0"  # Using a stable version
  FLUTTER_TAR="flutter_linux_${FLUTTER_VERSION}-stable_linux-x64.tar.xz"
  FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/$FLUTTER_TAR"
  
  echo "Downloading Flutter $FLUTTER_VERSION from $FLUTTER_URL"
  if ! wget -q --spider "$FLUTTER_URL"; then
    echo "Error: Flutter download URL is not accessible: $FLUTTER_URL"
    exit 1
  fi
  
  wget -q "$FLUTTER_URL"
  if [ ! -f "$FLUTTER_TAR" ]; then
    echo "Error: Failed to download Flutter"
    exit 1
  fi
  
  echo "Extracting Flutter..."
  tar -xf "$FLUTTER_TAR" -C "$HOME"
  export PATH="$HOME/flutter/bin:$PATH"
  echo "Flutter installed at: $(which flutter)"
  flutter --version
fi

# Set up environment
export FLUTTER_ROOT="$HOME/flutter"
export PUB_CACHE="$HOME/.pub-cache"
export PATH="$FLUTTER_ROOT/bin:$FLUTTER_ROOT/bin/cache/dart-sdk/bin:$PUB_CACHE/bin:$PATH"

# Enable Flutter web
echo "Setting up Flutter web..."
flutter config --enable-web
flutter doctor -v

# Create .env file
echo "Creating .env file..."
cat > .env <<EOF
API_BASE_URL=https://scentryx-backend.onrender.com/api
FIREBASE_PROJECT_ID=scentryx-13554
EOF

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Build the app
echo "Building web release..."
flutter build web --release --verbose

echo "Build completed successfully!"