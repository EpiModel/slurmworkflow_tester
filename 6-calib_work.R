# Plays the role of `swfcalib::calibration_step2`: one item of the wave.
#   `item`: the map item (1 to the size set by `calib_plan`)
calib_dir <- file.path(Sys.getenv("SWF_RUN_DIR"), "calib")
iter <- readLines(file.path(calib_dir, "iteration"))
submission <- slurmworkflow::get_workflow_submission()

cat(
  "Iteration", iter, "- item", item,
  "- task", Sys.getenv("SLURM_ARRAY_TASK_ID"),
  "- offset", submission[["data.map.offset"]],
  "- total", submission[["data.map.total"]], "\n"
)
if ("opt.comment" %in% names(submission)) {
  cat("One-shot comment:", submission[["opt.comment"]], "\n")
}
file.create(file.path(calib_dir, paste0("iter", iter, "_item", item)))
