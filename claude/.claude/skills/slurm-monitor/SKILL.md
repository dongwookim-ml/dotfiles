---
name: slurm-monitor
description: Monitor Slurm cluster resources and dynamically schedule GPU jobs. Checks job status, optimizes parallelism across partitions, enforces -q hpgpu for A100/H200 partitions, and prioritizes non-scarce GPU resources.
---

# Slurm Resource Monitor & Job Scheduler

Monitor the cluster and dynamically schedule experiments to maximize GPU utilization.

## Workflow

1. **Check cluster status**: Use `mcp__slurm__cluster_info` and `mcp__slurm__list_jobs` to assess current resource availability (available GPUs, running/pending jobs, partition states).

2. **Optimize parallelism**: Compare available GPUs against the compute requirements of target experiments. If resources allow, scale up by submitting additional jobs to fully utilize parallel execution capacity.

3. **Partition constraints**: When submitting jobs to any of these partitions, **always** append `-q hpgpu` to the submission command:
   - A100-40GB
   - A100-80GB
   - H200

4. **Resource prioritization**: Treat A100 and H200 partitions as **scarce resources** — they consume user priority quotas very quickly. Follow this priority order:
   - **First**: Use other available GPU partitions (e.g., V100, RTX, L40, etc.)
   - **Last resort**: A100 and H200 partitions, only when other GPUs are insufficient or unavailable

5. **Report**: After each check, summarize:
   - Current cluster utilization (running jobs, available GPUs by partition)
   - Actions taken (jobs submitted, scaled up/down, waiting)
   - Any issues or warnings (e.g., all GPUs busy, jobs failing)

## Recurring Mode

To run this on an interval, combine with the `/loop` skill:
```
/loop 10m /slurm-monitor
```

## Notes

- Do not cancel or modify jobs that were manually submitted by the user unless explicitly asked.
- If no experiments are queued or defined, just report cluster status and exit.
- When scaling down, prefer to hold off on new submissions rather than cancelling running jobs.
