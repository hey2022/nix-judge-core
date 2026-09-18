#!/usr/bin/env bash
set -euo pipefail

nix build .#gcc -o ./result-gcc
nix build .#clang -o ./result-clang
nix build .#python3 -o ./result-python

GCC_ENV=$(readlink -f ./result-gcc)
CLANG_ENV=$(readlink -f ./result-clang)
PYTHON_ENV=$(readlink -f ./result-python)

CONF_FILE="$(pwd)/isolate.conf"
BOX_ID=0

# www.ucw.cz/isolate/isolate.1.html
run_isolate() {
    sudo ISOLATE_CONFIG_FILE="$CONF_FILE" isolate --box-id=$BOX_ID --no-default-dirs "$@"
}

BOX_DIR=$(run_isolate --init)
echo "Sandbox Directory: $BOX_DIR"

sudo tee "$BOX_DIR/main.cpp" > /dev/null << 'EOF'
#include <iostream>

int main() {
    std::cout << "Hello, world!" << std::endl;
    return 0;
}
EOF

sudo tee "$BOX_DIR/main.py" > /dev/null << 'EOF'
print("Hello, world!")
EOF

# Pretend I managed to do permissions properly lol
sudo chmod 777 "$BOX_DIR"

echo "Building C++ with g++..."
run_isolate \
    --dir=/box="$BOX_DIR":rw \
    --dir=/tmp:tmp \
    --dir=/nix/store \
    --dir=/usr="$GCC_ENV" \
    --chdir=/box \
    --processes=10 \
    --run -- /usr/bin/g++ -std=c++20 main.cpp

echo "Running C++..."
run_isolate \
    --dir=/box="$BOX_DIR" \
    --dir=/tmp:tmp \
    --dir=/nix/store \
    --chdir=/box \
    --time=1.0 \
    --processes=1 \
    --run -- ./a.out

echo -e "\nBuilding C++ with clang++..."
run_isolate \
    --dir=/box="$BOX_DIR":rw \
    --dir=/tmp:tmp \
    --dir=/nix/store \
    --dir=/usr="$CLANG_ENV" \
    --chdir=/box \
    --processes=10 \
    --run -- /usr/bin/clang++ -std=c++20 main.cpp

echo "Running C++..."
run_isolate \
    --dir=/box="$BOX_DIR" \
    --dir=/tmp:tmp \
    --dir=/nix/store \
    --chdir=/box \
    --time=1.0 \
    --processes=1 \
    --run -- ./a.out

echo -e "\nRunning Python..."
run_isolate \
    --dir=/box="$BOX_DIR" \
    --dir=/tmp:tmp \
    --dir=/nix/store \
    --dir=/usr="$PYTHON_ENV" \
    --chdir=/box \
    --time=1.0 \
    --processes=1 \
    --run -- /usr/bin/python3 main.py

run_isolate --cleanup
