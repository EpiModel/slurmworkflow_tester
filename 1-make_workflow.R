library(slurmworkflow)
source("0-settings.R")

# Workflow creation ------------------------------------------------------------
if (local_run) unlink(file.path("workflows", wf_name), recursive = TRUE)

wf <- create_workflow(
  wf_name = wf_name,
  default_sbatch_opts = hpc_config
)

# setup - install renv and slurmworkflow on the HPC (skipped locally)
wf <- add_workflow_step(
  wf_summary = wf,
  step_name = "setup",
  step_tmpl = step_tmpl_bash_lines(
    bash_lines = c(
      if (git_pull) "git pull",
      load_r_sh,
      "Rscript -e \"renv::init(bare = TRUE, force = TRUE)\"",
      paste0(
        "Rscript -e \"renv::install(c('future.apply', '",
        slurmworkflow_ref, "'), prompt = FALSE)\""
      )
    )
  ),
  sbatch_opts = list(
    "mem" = "4G",
    "cpus-per-task" = 2,
    "time" = 20
  )
)

# rscript - copy the script in the workflow and run it on the HPC
wf <- add_workflow_step(
  wf_summary = wf,
  step_name = "rscript",
  step_tmpl = step_tmpl_rscript(
    r_script = "2-test_rscript.R",
    setup_lines = load_r_sh
  ),
  sbatch_opts = list(
    "mem" = "4G",
    "cpus-per-task" = 1,
    "time" = "00:10:00"
  )
)

# do_call_twice - source a script that is on the HPC. The script runs its own
#   step a second time with `change_next_workflow_step()`.
wf <- add_workflow_step(
  wf_summary = wf,
  step_name = "do_call_twice",
  step_tmpl = step_tmpl_do_call_script(
    r_script = "3-test_do_call.R",
    args = list(var1 = "ABC", var2 = "DEF"),
    setup_lines = load_r_sh
  ),
  sbatch_opts = list(
    "cpus-per-task" = 1,
    "time" = "00:10:00",
    "mem" = "4G"
  )
)

# map_slices - map with chunks (max_array_size < length(iterator)): 5 items
#   are submitted as 3 arrays of 2, 2 and 1 tasks.
cores_to_use <- 2
wf <- add_workflow_step(
  wf_summary = wf,
  step_name = "map_slices",
  step_tmpl = step_tmpl_map_script(
    r_script = "4-test_map.R",
    iterator1 = 1:5,
    iterator2 = 6:10,
    MoreArgs = list(
      ncores = cores_to_use,
      var1 = "IJK",
      var2 = "LMN"
    ),
    setup_lines = load_r_sh,
    max_array_size = 2
  ),
  sbatch_opts = list(
    "cpus-per-task" = cores_to_use,
    "time" = "00:10:00",
    "mem-per-cpu" = "4G"
  )
)

# bash_steer - a pure bash step (no R) using the `swf` command: it lists the
#   steps and sets a one-shot option on the next submission of `calib_work`.
#   `calib_plan` adds the array size on top of it (overrides aggregate).
wf <- add_workflow_step(
  wf_summary = wf,
  step_name = "bash_steer",
  step_tmpl = step_tmpl_bash_lines(c(
    "echo \"Pure bash step $SWF_CUR ($SWF_CUR_NAME) of run $SWF_RUN_ID\"",
    "\"$SWF_CMD\" steps",
    "\"$SWF_CMD\" override calib_work --opt \"comment=set by bash_steer: a b * \\$HOME\""
  )),
  sbatch_opts = list(
    "cpus-per-task" = 1,
    "time" = "00:05:00",
    "mem" = "1G"
  )
)

# calibration-like loop ---------------------------------------------------------
#   calib_plan -> calib_work -> calib_plan -> ... -> wrap_up
#   Each iteration of `calib_plan` sets the size of the next `calib_work` map:
#   4, 7, 0 (skipped) then 3 items. `calib_work` holds at most 8 items and
#   runs them by slices of 3 tasks. Its static `next_step` goes back to
#   `calib_plan`, which ends the loop with `change_next_workflow_step()`.
calib_sizes <- c(4, 7, 0, 3)

wf <- add_workflow_step(
  wf_summary = wf,
  step_name = "calib_plan",
  step_tmpl = step_tmpl_do_call_script(
    r_script = "5-calib_plan.R",
    args = list(sizes = calib_sizes),
    setup_lines = load_r_sh
  ),
  sbatch_opts = list(
    "cpus-per-task" = 1,
    "time" = "00:10:00",
    "mem" = "2G"
  )
)

wf <- add_workflow_step(
  wf_summary = wf,
  step_name = "calib_work",
  next_step = "calib_plan",
  step_tmpl = step_tmpl_map_script(
    r_script = "6-calib_work.R",
    item = 1:8,
    setup_lines = load_r_sh,
    max_array_size = 3
  ),
  sbatch_opts = list(
    "cpus-per-task" = 1,
    "time" = "00:10:00",
    "mem" = "2G"
  )
)

# failure handling ---------------------------------------------------------------
#   By default a failed step stops the workflow. These two steps fail on
#   purpose with `on_failure = "continue"`, so the run goes on and `wrap_up`
#   checks the failure markers they left.

# fail_continue - a map whose item 2 fails: marker `<array job>_1`, code 1
wf <- add_workflow_step(
  wf_summary = wf,
  step_name = "fail_continue",
  on_failure = "continue",
  step_tmpl = step_tmpl_map(
    FUN = function(i) {
      if (i == 2) stop("planned failure of item 2")
      cat("item", i, "ok\n")
    },
    i = 1:3,
    setup_lines = load_r_sh
  ),
  sbatch_opts = list(
    "cpus-per-task" = 1,
    "time" = "00:05:00",
    "mem" = "1G"
  )
)

# timeout_kill - killed by Slurm at its 1 minute time limit (SIGTERM):
#   marker with code 143. Locally (fake Slurm, no time limit) the payload
#   sends itself SIGTERM instead.
wf <- add_workflow_step(
  wf_summary = wf,
  step_name = "timeout_kill",
  on_failure = "continue",
  step_tmpl = step_tmpl_bash_lines(c(
    "echo \"start: $(date)\"",
    if (local_run) "kill -TERM $$" else "sleep 300",
    "echo 'this line must never be printed'"
  )),
  sbatch_opts = list(
    "cpus-per-task" = 1,
    "time" = 1,
    "mem" = "1G"
  )
)

# wrap_up - check that every planned item ran exactly once, mail at the end
wf <- add_workflow_step(
  wf_summary = wf,
  step_name = "wrap_up",
  step_tmpl = step_tmpl_do_call_script(
    r_script = "7-wrap_up.R",
    args = list(sizes = calib_sizes),
    setup_lines = load_r_sh
  ),
  sbatch_opts = list(
    "cpus-per-task" = 1,
    "time" = "00:10:00",
    "mem" = "2G",
    "mail-type" = "END"
  )
)
