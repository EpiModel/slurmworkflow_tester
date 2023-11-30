cat(paste0("var1 = ", var1, ", var2 = ", var2))

if (!file.exists("did_run")) {
  cat("First Run")
  file.create("did_run")
  current_step <- slurmworkflow::get_current_workflow_step()
  slurmworkflow::change_next_workflow_step(current_step)
} else {
  cat("Second Run")
  file.remove("did_run")
}
