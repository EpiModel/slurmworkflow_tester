# EDIT:
#   Put here the shell lines needed to load R on the HPC.
load_r_sh <- c(
  ". /projects/epimodel/spack/share/spack/setup-env.sh",
  "spack load r@4.6.1"
)

# EDIT:
#   your mail address to receive end of jobs notifications
#   the partition you use
#   the account to use (not on all system)
hpc_config <- list(
  "mail-user" = Sys.getenv("HPC_MAIL_USER", "<user>@<provider>"),
  "partition" = Sys.getenv("SWF_TESTER_PARTITION", "epimodel"),
  # "account"   = "csde"
  "mail-type" = "FAIL"
)

# EDIT:
#   the version of slurmworkflow installed on the HPC by the `setup` step
#   (any `remotes`-style reference understood by `renv::install()`, or the
#   absolute path of a slurmworkflow checkout on the HPC).
slurmworkflow_ref <- Sys.getenv(
  "SWF_TESTER_SWF_REF", "EpiModel/slurmworkflow@feature/dynamic-steps"
)

# EDIT:
#   whether the `setup` step runs `git pull` (FALSE when the project was
#   copied to the HPC without a remote to pull from).
git_pull <- !identical(Sys.getenv("SWF_TESTER_GIT_PULL"), "false")

# Local dry run with the fake Slurm of slurmworkflow (see `local/README.md`):
# `SWF_TESTER_LOCAL=true Rscript 1-make_workflow.R` builds
# "workflows/test_slurmworkflow_local" without the HPC setup lines.
local_run <- identical(Sys.getenv("SWF_TESTER_LOCAL"), "true")
if (local_run) {
  load_r_sh <- character()
}
wf_name <- if (local_run) "test_slurmworkflow_local" else "test_slurmworkflow"
