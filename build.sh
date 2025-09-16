#!/bin/bash

# ================================================
# Complicated Multithreaded Build Script (build.sh)
# No sleep, CPU + IO heavy, runs ~30+ minutes
# ================================================

set -e
set -o pipefail

LOG_FILE="build.log"
> "$LOG_FILE"

echo "🚀 Starting multithreaded build..." | tee -a "$LOG_FILE"
START_TIME=$(date +%s)

mkdir -p build output tmp

# ------------------------------------------------
# Step 1: Generate large random files (parallel)
# ------------------------------------------------
echo "📂 Generating large random files..." | tee -a "$LOG_FILE"
for i in {1..20}; do
  (
    dd if=/dev/urandom of=tmp/random_$i.bin bs=50M count=5 status=none
    echo "   → random_$i.bin generated" >> "$LOG_FILE"
  ) &
done
wait

# ------------------------------------------------
# Step 2: Parallel compression
# ------------------------------------------------
echo "📦 Compressing files (parallel gzip)..." | tee -a "$LOG_FILE"
for f in tmp/random_*.bin; do
  (
    gzip -c "$f" > "$f.gz"
    echo "   → Compressed $f" >> "$LOG_FILE"
  ) &
done
wait

# ------------------------------------------------
# Step 3: Heavy hashing in parallel
# ------------------------------------------------
echo "🔐 Hashing data chunks..." | tee -a "$LOG_FILE"
for gz in tmp/*.gz; do
  (
    for j in {1..50}; do
      sha256sum "$gz" >> "$LOG_FILE"
    done
  ) &
done
wait

# ------------------------------------------------
# Step 4: Simulated Compilation Workloads
# (lots of gcc calls on dummy C files in parallel)
# ------------------------------------------------
echo "🛠️ Simulating compilation..." | tee -a "$LOG_FILE"
for i in {1..200}; do
  (
    echo "int main(){return $i;}" > build/file_$i.c
    gcc -O2 -o build/file_$i build/file_$i.c
    ./build/file_$i || true
    echo "   → Compiled file_$i.c" >> "$LOG_FILE"
  ) &
done
wait

# ------------------------------------------------
# Step 5: Repeated Archiving
# ------------------------------------------------
echo "📦 Creating large tarballs repeatedly..." | tee -a "$LOG_FILE"
for i in {1..15}; do
  (
    tar -cf output/archive_$i.tar tmp/ > /dev/null 2>&1
    gzip -f output/archive_$i.tar
    echo "   → archive_$i.tar.gz created" >> "$LOG_FILE"
  ) &
done
wait

# ------------------------------------------------
# Step 6: Stress test with matrix multiplications
# ------------------------------------------------
echo "🧮 Running math-heavy workloads..." | tee -a "$LOG_FILE"
for i in {1..8}; do
  (
    python3 - << 'EOF'
import numpy as np
for k in range(1000):
    a = np.random.rand(500, 500)
    b = np.random.rand(500, 500)
    np.dot(a, b)
EOF
    echo "   → Thread $i completed math load" >> "$LOG_FILE"
  ) &
done
wait

# ------------------------------------------------
# Done
# ------------------------------------------------
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "✅ Build finished in $((ELAPSED/60)) minutes and $((ELAPSED%60)) seconds." | tee -a "$LOG_FILE"
