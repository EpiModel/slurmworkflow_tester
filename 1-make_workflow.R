# remotes::install_github("EpiModel/slurmworkflow")
library(slurmworkflow)
source("0-settings.R")

# Workflow creation ------------------------------------------------------------
wf <- create_workflow(
  wf_name = "test_slurmworkflow",
  default_sbatch_opts = hpc_config
)

# step1 - setup renv and slurmworkflow on the HPC
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_bash_lines(
    bash_lines = c(
      "git pull",
      load_r_sh,
      "Rscript -e \"renv::init(bare = TRUE, force = TRUE)\"",
      "Rscript -e \"renv::install(c('future.apply','EpiModel/slurmworkflow'))\""
    )
  ),
  sbatch_opts = list(
    "mem" = "4G",
    "cpus-per-task" = 2,
    "time" = 20
  )
)

# step2 - copy the script in the Workflow and run it on the HPC
wf <- add_workflow_step(
  wf_summary = wf,
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

# step3 - source a script that's on the HPC
#   Wrapper around `step_tmpl_do_call`. No need to test it as well
wf <- add_workflow_step(
  wf_summary = wf,
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

# step4 - source a script
#   test map with chuncks (max_array_size < length(iterator))
#   Wrapper around `step_tmpl_map`. No need to test it as well
cores_to_use <- 2
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_map_script(
    r_script = "4-test_map.R",
    # arguments passed to the script
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

# step5 - Simple do_call
#   mostly to get an finishing e-mail
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call(
    what = function(v1, v2) cat(paste0("var1 = ", v1, ", var2 = ", v2)),
    args = list(v1 = "XYZ", v2 = "UVW"),
    setup_lines = load_r_sh
  ),
  sbatch_opts = list(
    "cpus-per-task" = 1,
    "time" = "00:10:00",
    "mem" = "4G",
    "mail-type" = "END"
  )
)
