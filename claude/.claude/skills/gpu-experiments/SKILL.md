---
name: gpu-experiments
description: Plan, launch, and manage ML experiments on the lab GPU resources. Use when the user wants to run training or experiments on GPUs, check GPU availability, pick where to run a job, or stage data between machines. Covers interactive nodes a-i, the b200-2 server, and the ai2 Slurm cluster.
---

# GPU Experiments Manager

Source of truth for hardware, storage, QOS, and quotas: `references/resource-guide.md`.
Read it before making resource decisions. This skill is the workflow; the guide is the data.

Works from any machine whose `~/.ssh/config` has the lab host aliases (`a`..`i`,
`b200-2`, `ai2`, `seoul`), including the laptop, since every step runs over `ssh`.
Absolute paths below are paths on the remote machines, not on the machine you
invoke from.

## 1. Choose the pool

| Need | Pool |
|------|------|
| Quick run, debugging, <=48 GB VRAM | Interactive nodes: `g`/`i` (A6000 48 GB), `c`/`e`/`f` (3090), `d`/`h` (A5000) |
| Batch jobs, many GPUs, queueing | Slurm via `ai2` |
| >80 GB VRAM per GPU or B200-class throughput | `b200-2` (8x B200 180 GB, needs CUDA 12.8+ builds) |

On Slurm, prefer plentiful partitions (`RTX3090`, `A5000`, `A6000`, `L40S`,
`RTX6000ADA`) and use A100/H200 only when the job needs the VRAM or bandwidth.

## 2. Check availability

- Interactive nodes and b200: `scripts/gpu_avail.sh` (all) or `scripts/gpu_avail.sh g i` (specific).
- Slurm: `scripts/gpu_avail.sh ai2`, or the `mcp__slurm__*` tools if connected.
- A GPU is free when memory used is near zero AND utilization is near zero. Never
  assume; always check right before launching.

## 3. Launch

### Interactive nodes (no scheduler; shared politely)

```bash
ssh <node> 'tmux new -d -s <exp-name> "
  source /data_seoul/dongwoo/conda_init.sh &&
  conda activate <env> &&
  CUDA_VISIBLE_DEVICES=<ids> python train.py > /data_seoul/dongwoo/logs/<exp-name>.log 2>&1"'
```

Rules: always set `CUDA_VISIBLE_DEVICES` to the specific free GPUs; always run
inside tmux; write a log file; never take GPUs that show nonzero memory use.

### Slurm

Use `mcp__slurm__*` tools when available (they auto-inject `--qos=hpgpu`),
otherwise `ssh ai2` and `sbatch`. Key constraints: `--qos=hpgpu` for A100-SXM4
and H200 partitions, 16 GPU/user on hpgpu, 64 GPU total, 3-day MaxTime
(checkpoint and resubmit for longer). Template and partition table are in the
guide. For recurring monitoring/scheduling, use the `/slurm-monitor` skill.

### b200-2

No scheduler; same tmux discipline as interactive nodes. Storage is local
(`/home/postec_dong`), not the Seoul NFS; copy code and data in first.

## 4. Data staging (NFS discipline)

- Pack datasets with many small files into one archive (tar/WebDataset/HDF5/LMDB)
  before moving or training over NFS.
- Stage the packed file to node-local disk at job start; read locally during training.
- Write checkpoints locally, `rsync` back to `/data/dongwoo` (seoul) or
  `/home/dongwookim` (cluster) at the end.

## 5. Monitor and finish

- Follow progress via the log file (`tail -f` over ssh) or `mcp__slurm__*` job tools.
- Verify the process actually started and is on the intended GPUs
  (`nvidia-smi` shows your PID) before walking away.
- For anything long-running, send a completion notification with the
  `/slack-notify` skill, including exp name, runtime, and final metric.

## Hard rules

- Do not kill or nice other users' processes.
- Do not occupy all GPUs of an interactive node by default.
- Do not stream thousands of small files off NFS in a dataloader.
- On failure, read the log before resubmitting; do not retry blindly.
