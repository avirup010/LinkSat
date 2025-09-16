#!/bin/bash

# ================================================
# CPU-Heavy Build Script (build.sh)
# Runs ~10 minutes without filling ephemeral storage
# ================================================

set -e
set -o pipefail

LOG_FILE="build.log"
> "$LOG_FILE"

echo "🚀 Starting CPU-heavy build (~10 mins)..." | tee -a "$LOG_FILE"
START_TIME=$(date +%s)

mkdir -p build

# ------------------------------------------------
# Step 1: Parallel CPU Hashing (smaller workload)
# ------------------------------------------------
echo "🔐 Running hashing workloads..." | tee -a "$LOG_FILE"
for i in {1..4}; do
  (
    for j in {1..5000}; do
      echo "data-$i-$j" | sha256sum >> /dev/null
    done
    echo "   → Hash thread $i completed" >> "$LOG_FILE"
  ) &
done
wait

# ------------------------------------------------
# Step 2: Prime Number Calculations
# ------------------------------------------------
echo "🧮 Calculating primes..." | tee -a "$LOG_FILE"
for i in {1..4}; do
  (
    python3 - << 'EOF'
def is_prime(n):
    if n < 2:
        return False
    if n % 2 == 0 and n != 2:
        return False
    r = int(n ** 0.5)
    for f in range(3, r+1, 2):
        if n % f == 0:
            return False
    return True

count = 0
for num in range(10**6, 10**6 + 80000):
    if is_prime(num):
        count += 1
print(f"Thread primes found: {count}")
EOF
    echo "   → Prime thread $i completed" >> "$LOG_FILE"
  ) &
done
wait

# ------------------------------------------------
# Step 3: Matrix Multiplication (reduced loops)
# ------------------------------------------------
echo "📊 Running matrix multiplications..." | tee -a "$LOG_FILE"
for i in {1..4}; do
  (
    python3 - << 'EOF'
import numpy as np
for k in range(300):
    a = np.random.rand(400, 400)
    b = np.random.rand(400, 400)
    np.dot(a, b)
EOF
    echo "   → Matrix thread $i completed" >> "$LOG_FILE"
  ) &
done
wait

# ------------------------------------------------
# Step 4: Compression Loop
# ------------------------------------------------
echo "📦 Running repeated compression..." | tee -a "$LOG_FILE"
for i in {1..4}; do
  (
    for j in {1..1000}; do
      echo "compress-$i-$j-$(date +%s%N)" | gzip -c > /dev/null
    done
    echo "   → Compression thread $i completed" >> "$LOG_FILE"
  ) &
done
wait

# ------------------------------------------------
# Done
# ------------------------------------------------
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "✅ Build finished in $((ELAPSED/60)) minutes and $((ELAPSED%60)) seconds." | tee -a "$LOG_FILE"
