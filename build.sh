#!/bin/bash
set -e

# ==============================
# Heavy Build Script (~20 mins)
# ==============================
# Purely CPU-intensive workload
# No sleep used
# Uses parallelism to keep CPU busy

# Number of threads (tune this based on machine cores)
THREADS=$(nproc)

echo "[INFO] Starting heavy build with $THREADS threads..."
START=$(date +%s)

# 1. Generate large prime numbers in parallel
prime_task() {
    local ID=$1
    echo "[TASK $ID] Starting prime generation..."
    # Bruteforce primes up to a very large number
    for ((n=100000000; n<=100002000; n++)); do
        is_prime=1
        for ((i=2; i*i<=n; i++)); do
            if (( n % i == 0 )); then
                is_prime=0
                break
            fi
        done
        if (( is_prime == 1 )); then
            echo "[TASK $ID] Prime: $n" >> primes_$ID.log
        fi
    done
    echo "[TASK $ID] Finished prime generation."
}

export -f prime_task

# Run multiple prime finding jobs in parallel
seq 1 $THREADS | xargs -n1 -P$THREADS bash -c 'prime_task "$@"' _

# 2. Heavy matrix multiplications
matrix_task() {
    local ID=$1
    echo "[TASK $ID] Starting matrix multiplications..."
    SIZE=600
    for run in {1..20}; do
        python3 - <<EOF
import numpy as np
a = np.random.rand($SIZE, $SIZE)
b = np.random.rand($SIZE, $SIZE)
c = a @ b
EOF
        echo "[TASK $ID] Matrix run $run completed."
    done
    echo "[TASK $ID] Finished matrix multiplications."
}

export -f matrix_task

# Run matrix multiplications in parallel
seq 1 $THREADS | xargs -n1 -P$THREADS bash -c 'matrix_task "$@"' _

# 3. Compression & hashing workload
echo "[INFO] Starting compression workload..."
for i in {1..10}; do
    head -c 500M </dev/urandom >file_$i.bin
    gzip -c file_$i.bin >file_$i.gz
    sha256sum file_$i.gz >>hashes.log
    rm file_$i.bin file_$i.gz
    echo "[INFO] Compression task $i completed."
done

END=$(date +%s)
echo "[INFO] Build completed in $(( (END-START)/60 )) minutes."

