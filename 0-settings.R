# EDIT:
#   Put here the shell lines needed to load R on the HPC.
load_r_sh <- c(
  ". /projects/epimodel/spack/share/spack/setup-env.sh",
  "spack load r@4.2.1"
)

# EDIT:
#   your mail address to receive end of jobs notifications
#   the partition you use
#   the account to use (not on all system)
hpc_config <- list(
  "mail-user" = "<user>@<provider>",
  "partition" = "epimodel",
  # "account"   = "csde"
  "mail-type" = "FAIL"
)
