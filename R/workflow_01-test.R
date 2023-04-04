library(slurmworkflow)

# Workflow creation ------------------------------------------------------------
wf <- create_workflow(
  wf_name = "test_slurmworkflow",
  default_sbatch_opts = list(
    "partition" = "epimodel",
    "mail-type" = "FAIL",
    "mail-user" = "<user>@emory.edu"
  )
)

# step1
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_bash_script(
    bash_script = "manual_renv.sh"
  ),
  sbatch_opts = list(
    "mem" = "4G",
    "cpus-per-task" = 2,
    "time" = 20
  )
)

setup_lines <- c(
  ". /projects/epimodel/spack/share/spack/setup-env.sh",
  "spack load r@4.2.1"
)

# step2
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_rscript(
    r_script = "dummy.R",
    setup_lines = setup_lines
  ),
  sbatch_opts = list(
    "mem" = "4G",
    "cpus-per-task" = 1,
    "time" = 10
  )
)

# step3
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call_script(
    r_script = "R/01-test_do_call.R",
    args = list(var1 = "ABC", var2 = "DEF"),
    setup_lines = setup_lines
  ),
  sbatch_opts = list(
    "cpus-per-task" = 1,
    "time" = "00:10:00",
    "mem" = "4G"
  )
)

# step4
# test map with chuncks (max_array_size < length(iterator))
cores_to_use <- 2
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_map_script(
    r_script = "R/02-test_map.R",
    # arguments passed to the script
    iterator1 = 1:5,
    iterator2 = 6:10,
    MoreArgs = list(
      ncores = cores_to_use,
      var1 = "IJK",
      var2 = "LMN"
    ),
    setup_lines = setup_lines,
    max_array_size = 2
  ),
  sbatch_opts = list(
    "cpus-per-task" = cores_to_use,
    "time" = "00:10:00",
    "mem-per-cpu" = "4G"
  )
)

# step5
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call(
    what = function(var1, var2) {
      cat(paste0("var1 = ", var1, ", var2 = ", var2))
    },
    args = list(var1 = "XYZ", var2 = "UVW"),
    setup_lines = setup_lines
  ),
  sbatch_opts = list(
    "cpus-per-task" = 1,
    "time" = "00:10:00",
    "mem" = "4G",
    "mail-type" = "END"
  )
)
