#!/bin/bash

# 1. Unduh Flutter SDK (Shallow clone untuk kecepatan)
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK..."
  git clone --depth 1 https://github.com/flutter/flutter.git -b stable
fi

# 2. Tambahkan Flutter ke PATH sistem Vercel
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Persiapan build
echo "Enabling web support..."
flutter config --enable-web

echo "Getting dependencies..."
flutter pub get

# 4. Build aplikasi untuk Web
echo "Building Flutter Web..."
flutter build web --release

echo "Build complete!"
