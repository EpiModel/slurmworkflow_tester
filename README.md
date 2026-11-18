# Test Workflow for `slurmworkflow`

This repo creates a workflow testing
[`slurmworkflow`](https://github.com/EpiModel/slurmworkflow)'s capabilities on
an HPC. It targets slurmworkflow 0.2.0 (branch `feature/dynamic-steps`): named
steps, the `swf` command, one-shot overrides and dynamically sized maps.

## The workflow

| # | Step | What it tests |
|---|---|---|
| 1 | `setup` | bash step: `git pull`, renv, install slurmworkflow on the HPC |
| 2 | `rscript` | `step_tmpl_rscript` |
| 3 | `do_call_twice` | `step_tmpl_do_call_script`; runs itself a second time with `change_next_workflow_step()` |
| 4 | `map_slices` | `step_tmpl_map_script` with 5 items and `max_array_size = 2` (arrays of 2, 2, 1) |
| 5 | `bash_steer` | pure bash step (no R): `swf steps` and a one-shot `swf override` of `calib_work` |
| 6 | `calib_plan` | swfcalib-like planner: sets the size of the next `calib_work` with `set_map_size()` (4, 7, 0, 3 items), then ends the loop with `change_next_workflow_step("fail_continue")` |
| 7 | `calib_work` | map of up to 8 items, slices of 3 tasks, static `next_step = "calib_plan"` |
| 8 | `fail_continue` | map of 3 items whose item 2 fails on purpose; `on_failure = "continue"` |
| 9 | `timeout_kill` | killed by Slurm at its 1 minute time limit; `on_failure = "continue"` |
| 10 | `wrap_up` | checks every planned item ran exactly once and the 2 failure markers (codes 1 and 143); mails at the end |

`8-make_failstop_workflow.R` builds a second workflow, `test_slurmworkflow_failstop`:
`boom` exits with 3, and the default `on_failure = "stop"` must stop the
workflow before `never`.

## How To Use

- Create a new GitHub repository by clicking the green `Use this template`
  button above.
- Clone this new repo on your computer AND on the HPC (`git` is required on
  the HPC).
- On your local computer:
  - Setup [`renv`](https://rstudio.github.io/renv/index.html)
    - `renv::init(bare = TRUE)` - then restart R
    - Install packages:
      `renv::install(c("future.apply", "EpiModel/slurmworkflow@feature/dynamic-steps"))`
    - `renv::snapshot()`
  - Edit the "0-settings.R" script according to your setup (R module lines,
    mail, partition, account, and `slurmworkflow_ref`, the version the `setup`
    step installs on the HPC).
  - Commit your changes and push to GitHub (including the renv.lock file).
  - Run the script "1-make_workflow.R".

Send the generated workflow directory "workflows/test_slurmworkflow" to the
HPC:

```sh
# bash - local
scp -r workflows/test_slurmworkflow <user>@<hpc address>:<path_to_project_on_HPC>/workflows/
```

- On the HPC, `cd` into your project directory and start the workflow:

```sh
# bash - HPC
./workflows/test_slurmworkflow/swf start
```

`swf` must be executed, not sourced. If it is not executable (copied from
Windows): `chmod +x workflows/test_slurmworkflow/swf`.

Follow and control the run with:

```sh
./workflows/test_slurmworkflow/swf status            # current step, queue state, failures
./workflows/test_slurmworkflow/swf log               # controller log
./workflows/test_slurmworkflow/swf log -s calib_work # logs of the last calib_work job
./workflows/test_slurmworkflow/swf log -s calib_work -t 0 -f
./workflows/test_slurmworkflow/swf stop              # stop the run, cancel its jobs
./workflows/test_slurmworkflow/swf start -s calib_plan --force  # restart from a step
```

## Expected results

You should receive an e-mail a few minutes later for the end of `wrap_up`
(`Name=test_slurmworkflow_10_wrap_up ... COMPLETED, ExitCode 0`). Any other
`ExitCode`, or a FAIL mail, means something failed.

`./workflows/test_slurmworkflow/swf status` should then show the last
submission `step=10_wrap_up`, `Failed jobs (2)` (the planned ones), and the history should end
with `event=end`. `swf log -s wrap_up` should end with
`Loop check OK: 14 items over 4 iterations` and
`Failure check OK: 2 markers (codes 1 and 143)`.

`workflows/test_slurmworkflow/log/<run id>/` should contain:

- `controller.out`
- 1 `1_setup_*` file, 1 `2_rscript_*` file, 2 `3_do_call_twice_*` files
- 5 `4_map_slices_*` files (3 jobs)
- 1 `5_bash_steer_*` file
- 5 `6_calib_plan_*` files (iteration 3 has no `calib_work`: it is skipped)
- 14 `7_calib_work_*` files (6 jobs: 3+1, 3+3+1, 3)
- 3 `8_fail_continue_*` files, 1 `9_timeout_kill_*` file
- 1 `10_wrap_up_*` file

The first `calib_work` job carries the option set by the bash step
(`--comment=set by bash_steer: a b * $HOME`, one argument) and the later ones
do not: overrides are one-shot. `swf log -s calib_work` only shows the last
job; the controller log prints every `sbatch` command.

If so: SUCCESS! `slurmworkflow` is working correctly.

Then the failure workflow (built by `8-make_failstop_workflow.R`, copied like
the first one):

```sh
./workflows/test_slurmworkflow_failstop/swf start
./workflows/test_slurmworkflow_failstop/swf status
```

Expected: a FAIL mail from the controller, `swf status` reports
`Workflow stopped on error: step_failed:1_boom`, and `never` never ran (no
`never_ran` file in the run directory, no `2_never_*` log).

## Local dry run (no HPC)

`local/run_fake_slurm.sh` builds `workflows/test_slurmworkflow_local` (without
the HPC setup lines) and runs it from `rscript` onward with the fake Slurm
shipped in slurmworkflow's sources (`tests/fake_slurm`):

```sh
bash local/run_fake_slurm.sh ../slurmworkflow
```

R, the project's renv and a slurmworkflow 0.2.0 install are required. It ends
with `Local dry run OK`.
