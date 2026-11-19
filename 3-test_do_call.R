cat(paste0("var1 = ", var1, ", var2 = ", var2, "\n"))

# The flag lives in the run directory: a new run always starts fresh.
flag <- file.path(Sys.getenv("SWF_RUN_DIR"), "did_run")
if (!file.exists(flag)) {
  cat("First Run\n")
  file.create(flag)
  # DANGEROUS on purpose: run this same step again
  slurmworkflow::change_next_workflow_step(
    slurmworkflow::get_current_workflow_step_name()
  )
} else {
  cat("Second Run\n")
  file.remove(flag)
}
