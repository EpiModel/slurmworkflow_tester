# A second, tiny workflow checking that a failed step stops the workflow
# (the default `on_failure = "stop"`): `boom` exits with 3, so `never` must
# not run. Expected: `swf status` reports the error `step_failed:1_boom`, the
# controller mails a FAIL, and "never_ran" does not exist in the run directory.
library(slurmworkflow)
source("0-settings.R")

failstop_name <- paste0(wf_name, "_failstop")
if (local_run) unlink(file.path("workflows", failstop_name), recursive = TRUE)

wf <- create_workflow(
  wf_name = failstop_name,
  default_sbatch_opts = hpc_config
)

wf <- add_workflow_step(
  wf_summary = wf,
  step_name = "boom",
  step_tmpl = step_tmpl_bash_lines(c("echo 'failing on purpose'", "exit 3")),
  sbatch_opts = list("cpus-per-task" = 1, "time" = 5, "mem" = "1G")
)

wf <- add_workflow_step(
  wf_summary = wf,
  step_name = "never",
  step_tmpl = step_tmpl_bash_lines(c(
    "echo 'this step must not run'",
    "touch \"$SWF_RUN_DIR/never_ran\""
  )),
  sbatch_opts = list("cpus-per-task" = 1, "time" = 5, "mem" = "1G")
)
