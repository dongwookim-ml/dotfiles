# GPU Resource Guide

Practical guide to the GPU compute available from this account. It covers three
independent resource pools, how to reach them, what hardware each has, how the
storage is laid out, and how to run jobs without fighting the network filesystem.

All hardware, storage, and Slurm facts below were read directly from the live
systems, not assumed.

---

## 1. The three resource pools

You have access to three separate systems. They do **not** share a filesystem or
a login. Moving data between them means copying it (see Section 7).

| Pool | Access | Scheduler | GPUs | Shared storage |
|------|--------|-----------|------|----------------|
| **Interactive nodes** `a`..`i` | direct `ssh` | none (manual) | 55 GPUs, 2080Ti / 3090 / A5000 / A6000 | NFS `/data_seoul` |
| **B200 server** `b200-2` | direct `ssh` | none (manual) | 8x B200 (180 GB) | isolated |
| **Slurm cluster** `ai2` | `ssh` then `sbatch`/`srun` | Slurm 24.11 | ~700 GPUs, 2080Ti to H200 | `/home1`, `/home` |

`seoul` (alias `s`, also reachable as `stail`/`bypass`) is the **jump host and
NFS server**. It has no GPUs. It exports `/data` to the interactive nodes and is
the gateway the other pools are reached through.

---

## 2. Live utilization dashboard

A `gpustat-web` instance runs on `seoul` and polls every node once per minute.
It shows a GPU panel (per-host utilization and who is running what) next to a
Slurm panel.

- It listens on **`seoul:50009`** (the process is `gpustat_web ... --port 50009`).
- It monitors `atlanta beijing canberra dubai edinburgh florence geneva helsinki
  istanbul` (that is `a`..`i`), both B200 hosts, and `--slurm-host ai2`.

Reach it from your laptop with an SSH tunnel:

```bash
ssh -N -L 50009:localhost:50009 seoul   # then open http://localhost:50009
```

Check this **before** you start work on an interactive node, so you land on a GPU
nobody else is using.

---

## 3. Interactive GPU nodes (`a` .. `i`)

Plain Linux workstations on the internal `10.2.5.0/24` network. No scheduler, no
queue. You SSH in, pick free GPUs yourself, and run. Coordinate with other users
by watching the dashboard, because nothing stops two people using the same GPU.

### Inventory

| Alias | Host | IP | GPUs | VRAM each |
|-------|------|-----|------|-----------|
| `a` | atlanta | 10.2.5.2 | 2x RTX 2080 Ti + 2x RTX A5000 | 11 GB / 24 GB |
| `b` | beijing | 10.2.5.3 | 4x RTX 2080 Ti | 11 GB |
| `c` | canberra | 10.2.5.4 | 4x RTX 3090 | 24 GB |
| `d` | dubai | 10.2.5.5 | 4x RTX A5000 | 24 GB |
| `e` | edinburgh | 10.2.5.6 | 8x RTX 3090 | 24 GB |
| `f` | florence | 10.2.5.7 | 8x RTX 3090 | 24 GB |
| `g` | geneva | 10.2.5.8 | 8x RTX A6000 | 48 GB |
| `h` | helsinki | 10.2.5.9 | 8x RTX A5000 | 24 GB |
| `i` | istanbul | 10.2.5.10 | 7x RTX A6000 | 48 GB |

Pick by VRAM need: `g`/`i` (A6000, 48 GB) for the largest models, `c`/`e`/`f`
(3090) or `d`/`h` (A5000) for 24 GB work, `b` for small jobs.

### Access

From `seoul` (the jump host), the aliases connect directly:

```bash
ssh g          # -> geneva, 8x A6000
nvidia-smi
```

From your laptop the same aliases work through the `bypass` jump host defined in
`~/.ssh/config`, so `ssh g` works there too once your SSH config is in place.

Check what is free before claiming GPUs, on the dashboard or from `seoul`:

```bash
~/.claude/skills/gpu-experiments/scripts/gpu_avail.sh        # all of a..i + b200-2
~/.claude/skills/gpu-experiments/scripts/gpu_avail.sh g i    # specific nodes
```

The script prints a FREE/busy verdict per GPU from `nvidia-smi` memory and
utilization figures.

### Running a job

The conda install lives on the shared NFS at `/data/dongwoo/miniconda3`, so the
**same environment is visible on every interactive node and on `seoul`**. There
is nothing to install per node.

```bash
ssh f
source /data_seoul/dongwoo/conda_init.sh   # on a..i the share is /data_seoul
conda activate <env>

# claim specific GPUs (check the dashboard first)
export CUDA_VISIBLE_DEVICES=2,3
tmux new -s train                          # survive disconnects
python train.py
```

`conda_init.sh` auto-detects the mount, so `/data_seoul/dongwoo/conda_init.sh`
(on `a`..`i`) and `/data/dongwoo/conda_init.sh` (on `seoul`) both work.

Etiquette on these shared, unscheduled nodes:

- Always `export CUDA_VISIBLE_DEVICES` to the GPUs you claimed. Never grab all of
  them by default.
- Use `tmux` or `nohup` so a dropped SSH connection does not kill training.
- Local disk is small (the root filesystem, for example `atlanta` has ~140 GB
  free). It is not shared scratch. Keep datasets on NFS or stage them (Section 6).

---

## 4. B200 server (`b200-2`)

A single high-end node, external to the campus network.

- Reach it with `ssh b200-2` (`59.150.35.1:30101`, user `postec_dong`).
- **8x NVIDIA B200, 180 GB HBM3e each.** 72 CPU cores.
- Driver 580.95, so CUDA up to 13 is supported. B200 is compute capability 10.0,
  so you need **CUDA 12.8+** and a matching PyTorch build (for example the
  `cu128` wheels or a recent nightly). Older CUDA will not run on this GPU.
- Storage is container-local (`/home/postec_dong`, ~1.6 TB). It is **not** on the
  Seoul NFS. Copy code and data in explicitly (Section 7).

A second B200 host, `b200-1` / `b200-4` (`59.150.33.1:30301`, user `korea_bupj`),
is the one shown as `b200` on the dashboard. Use `b200-2` unless you have a reason
to use the other.

Use this node for the largest models and for anything that needs 180 GB per GPU
or B200-class throughput. It is a scarce, shared resource with no scheduler, so
check the dashboard and do not leave idle processes holding the GPUs.

---

## 5. Slurm cluster (`ai2`)

A real batch cluster (Slurm 24.11, OpenHPC). You log in to the scheduler node and
submit jobs; you do not SSH to compute nodes directly.

```bash
ssh ai2
```

### Storage (two tiers, separate quotas)

| Path | Backing | Quota | Use for |
|------|---------|-------|---------|
| `/home1/dongwookim` | local `sdb1` | **500 GB** | code, conda envs, small files (this is `$HOME`) |
| `/home/dongwookim` | NFS `192.168.10.254` | **1000 GB** | datasets, checkpoints, large files |

Keep your environment and repositories in `/home1` and put bulk data in `/home`.
Neither is connected to the Seoul NFS.

### Partitions and GPU types

Select the GPU type by choosing the partition. Current partitions (from `sinfo`):

| Partition | GPU type | VRAM | Nodes x GPUs | QOS needed |
|-----------|----------|------|--------------|------------|
| `RTX2080Ti` | RTX 2080 Ti | 11 GB | n1-6 (6-8 each) | `normal` |
| `TITANRTX` | Titan RTX | 24 GB | n7 x4 | `normal` |
| `RTX3090` | RTX 3090 | 24 GB | n8-34 (4-8 each) | `normal` |
| `A5000` | RTX A5000 | 24 GB | n35-41 x8 | `normal` |
| `A6000` | RTX A6000 | 48 GB | n42-46,60 x8 | `normal` |
| `RTX4090` | RTX 4090 | 24 GB | n71-75 x4 | `normal` |
| `RTX6000ADA` | RTX 6000 Ada | 48 GB | n61-70 x8 | `normal` |
| `L40S` | L40S | 48 GB | n81-86 x8 | `normal` |
| `A100-40GB-PCIe` | A100 PCIe | 40 GB | n47-48 x4 | `normal` |
| `A100-40GB` / `4A100` | A100 SXM4 | 40 GB | n49-50 x8 | **`hpgpu`** |
| `A100-80GB` | A100 SXM4 | 80 GB | n51-59,76-80 x8 | **`hpgpu`** |
| `H200` | H200 | 141 GB | n87-88 x8 | **`hpgpu`** |
| `H200-ZT` / `H200-PCIe-ZT` | H200 | 141 GB | n89-92 x8 | **`hpgpu`** |

Account limits (verified with `scontrol show partition` and `sacctmgr`):

- Every partition has **MaxTime 3 days** (`3-00:00:00`). Checkpoint and resubmit
  for longer runs.
- Total GPU cap across all your running jobs: **64 GPUs** (`GrpTRES gres/gpu=64`).
- `hpgpu` QOS caps you at **16 GPUs per user** and is **required** for the A100
  SXM4 partitions (`A100-40GB`, `A100-80GB`, `4A100`) and **all H200 partitions**.
  Add `--qos=hpgpu` there. The ZT partitions also accept a `zt` QOS this account
  does not have; use `hpgpu`.
- `add_hpgpu` is a variant of `hpgpu` with a 1-day MaxWall.
- Default QOS is `normal`; you also have `4a100` and `nogpu`.
- A100 and H200 consume priority quickly. Prefer `RTX3090`, `A5000`, `A6000`,
  `L40S`, or `RTX6000ADA` when they fit, and reserve A100/H200 for jobs that
  actually need the VRAM or bandwidth.

### CUDA modules

Loaded through Lmod. Available: `cuda/11.0` through `cuda/13.2`.

```bash
module load cuda/12.4
```

### Interactive session

```bash
srun -p A6000 --gres=gpu:1 -c 8 --mem=64G --pty bash
# A100-80GB needs hpgpu:
srun -q hpgpu -p A100-80GB --gres=gpu:4 -c 16 --mem=200G --pty bash
```

### Batch job template

```bash
#!/bin/bash
#SBATCH --job-name=train
#SBATCH --partition=A100-80GB
#SBATCH --qos=hpgpu
#SBATCH --gres=gpu:4
#SBATCH --cpus-per-task=32
#SBATCH --mem=200G
#SBATCH --time=1-00:00:00
#SBATCH --output=/home/dongwookim/logs/%x-%j.out

module load cuda/12.4
source ~/miniconda3/etc/profile.d/conda.sh   # or your env init
conda activate <env>

srun python train.py
```

Submit and manage:

```bash
sbatch job.sh
squeue --me
scancel <jobid>
sinfo -R          # why nodes are drained/down
sinfo -p A100-80GB -o "%P %.6D %.14F %G"   # free/idle GPUs in a partition
```

Column `NODES(A/I/O/T)` in `sinfo` reads allocated / idle / other / total. Aim
for partitions with a nonzero idle count.

### Claude Code integration

- `~/.claude/settings.json` registers a `slurm` MCP server that runs
  [`slurm-mcp`](https://github.com/dongwookim-ml/slurm-mcp) on `ai2` over SSH.
  In a Claude Code session the `mcp__slurm__*` tools submit, list, and cancel
  jobs, tail logs, and report GPU availability, with automatic `--qos=hpgpu`
  injection for partitions that need it.
- Skills: `/gpu-experiments` plans and launches runs across all three pools;
  `/slurm-monitor` watches the cluster and schedules queued experiments.

---

## 6. NFS and dataset packing (read this before large jobs)

The interactive-node share (`seoul:/data` mounted at `/data_seoul`) is a network
filesystem. Throughput for one big sequential file is fine, but **metadata
operations are slow**: opening, stat-ing, and reading thousands of small files
each pays a network round trip. A dataset stored as many small files (one image
or sample per file) will starve the GPU because the data loader spends its time
waiting on the network, not on disk.

Rules that keep the GPUs fed:

1. **Pack datasets into a few large files.** Convert a directory of many small
   files into sharded archives or a single-file format before training:
   - `tar` shards or **WebDataset** (`.tar` of samples, streamed sequentially)
   - **HDF5**, **LMDB**, or **zarr** for array/tensor datasets
   - a single `.npy`/`.npz`/parquet when it fits

   ```bash
   # many files -> one archive
   tar -cf /data/dongwoo/datasets/imagenet-train.tar -C /path/to/train .
   # or sharded webdataset-style
   tar -cf shard-000.tar -C train $(sed -n '1,10000p' filelist)
   ```

2. **Stage the archive to node-local disk once, then read locally.** Copy the
   packed file to the node's local disk (under your home or `/tmp` on the root
   filesystem) at job start, and point the loader there. This turns every epoch's
   reads into local reads. Watch free space; local disks are ~100-150 GB free.

3. **Write outputs locally, sync at the end.** Checkpointing thousands of small
   files straight to NFS is slow and hammers the server. Write to local disk (or
   a single archive) during the run, then `rsync` the result back to NFS once.

4. **Use enough dataloader workers** (`num_workers`) so decode/IO overlaps
   compute, but do not point hundreds of workers at raw NFS small files; that is
   the exact pattern this section exists to avoid.

The same logic applies on the Slurm cluster and B200: prefer packed formats,
stage to node-local scratch, avoid small-file storms on the shared filesystems.

---

## 7. Moving data between pools

The three pools are isolated, so transfers are explicit. Run them from `seoul`,
which can reach all of them. Compress in flight, and prefer moving one archive
over many files.

```bash
# Seoul NFS  ->  Slurm cluster (big data tier)
rsync -az --info=progress2 /data/dongwoo/datasets/set.tar ai2:/home/dongwookim/datasets/

# Seoul NFS  ->  B200 node
rsync -az --info=progress2 /data/dongwoo/proj/ b200-2:/home/postec_dong/proj/

# Pull results back
rsync -az ai2:/home/dongwookim/runs/exp1/ /data/dongwoo/runs/exp1/
```

`rsync -z` compresses on the wire. For a directory of many small files, `tar`
first and copy the single archive, then unpack on the far side; it is far faster
than rsync walking the tree file by file.

---

## 8. Quick reference

```
Dashboard      ssh -N -L 50009:localhost:50009 seoul   ->  http://localhost:50009

Interactive    ssh a|b|c|d|e|f|g|h|i     (55 GPUs, no scheduler)
  biggest VRAM   g, i   = A6000 48 GB
  24 GB          c,e,f (3090)  d,h (A5000)
  small          b      = 2080 Ti 11 GB
  env            source /data_seoul/dongwoo/conda_init.sh
  storage        /data_seoul/dongwoo   (= /data/dongwoo on seoul, 11 TB free)

B200           ssh b200-2               (8x B200 180 GB, need CUDA 12.8+)
  storage        /home/postec_dong      (local, ~1.6 TB, not shared)

Slurm          ssh ai2   (or the mcp__slurm__* tools in Claude Code)
  submit         sbatch job.sh   |  srun ... --pty bash
  A100 SXM4 + H200   add --qos=hpgpu  (16 GPU/user; 64 GPU total; 3-day MaxTime)
  scarce         use RTX3090/A5000/A6000/L40S first, A100/H200 last
  modules        module load cuda/12.4     (11.0 .. 13.2 available)
  code/env       /home1/dongwookim  (500 GB)
  data/ckpt      /home/dongwookim   (1000 GB)

Golden rule    pack datasets into few large files, stage to local disk,
               never stream thousands of small files off NFS.
```
