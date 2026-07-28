#!/bin/bash
# GPU availability across the lab resources.
# Usage: gpu_avail.sh [host ...]
#   default hosts: a b c d e f g h i
#   pass "ai2" to get the Slurm partition free/idle summary instead.
hosts=("$@")
[ ${#hosts[@]} -eq 0 ] && hosts=(a b c d e f g h i)

# macOS has no coreutils `timeout`; fall back to gtimeout, then to nothing
# (ssh's own ConnectTimeout still bounds the connect phase).
if command -v timeout >/dev/null; then TO=(timeout)
elif command -v gtimeout >/dev/null; then TO=(gtimeout)
else TO=(); fi
run() { if [ ${#TO[@]} -gt 0 ]; then "${TO[@]}" "$@"; else shift; "$@"; fi; }

for h in "${hosts[@]}"; do
  echo "=== $h ==="
  if [ "$h" = "ai2" ]; then
    run 40 ssh -o BatchMode=yes -o ConnectTimeout=20 ai2 \
      'sinfo -o "%P %.14F %G"' 2>/dev/null || echo "  (unreachable)"
    continue
  fi
  run 20 ssh -o BatchMode=yes -o ConnectTimeout=10 "$h" \
    'nvidia-smi --query-gpu=index,name,memory.used,memory.total,utilization.gpu --format=csv,noheader' \
    2>/dev/null | awk -F', ' '{
      used=$3+0; total=$4+0; util=$5+0
      state=(used<1500 && util<5) ? "FREE" : "busy"
      printf "  gpu%-2s %-28s %6d/%-6d MiB  util %3d%%  %s\n", $1, $2, used, total, util, state
    }'
  if [ "${PIPESTATUS[0]}" -ne 0 ]; then echo "  (unreachable)"; fi
done
