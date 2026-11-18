#!/bin/bash
# Dry run of the tester workflow on this computer, with the fake Slurm shipped
# in slurmworkflow's sources (tests/fake_slurm). Run it from the project root,
# with R and the project's renv available:
#
#   bash local/run_fake_slurm.sh [path to a slurmworkflow checkout]
#
# The `setup` step (git pull and renv on the HPC) is skipped: the run starts at
# `rscript`. Exit status: 0 when the workflow ended and `wrap_up` passed.
set -euo pipefail

if [[ ! -f 1-make_workflow.R ]]; then
  echo "Run this script from the root of the tester project." >&2
  exit 1
fi

SWF_REPO="$(realpath "${1:-../slurmworkflow}")"
if [[ ! -x "$SWF_REPO/tests/fake_slurm/sbatch" ]]; then
  echo "No fake Slurm in $SWF_REPO/tests/fake_slurm" >&2
  exit 1
fi

export PATH="$SWF_REPO/tests/fake_slurm:$PATH"
export FAKE_SLURM_DIR="$PWD/local/fake_slurm_state"
rm -rf "$FAKE_SLURM_DIR"
mkdir -p "$FAKE_SLURM_DIR"

SWF_TESTER_LOCAL=true Rscript 1-make_workflow.R
WF=workflows/test_slurmworkflow_local

"$WF/swf" steps
run_id="$("$WF/swf" start -s rscript)"
echo "Started run $run_id"
fake_slurm_run
"$WF/swf" status

if ! grep -q "event=end" "$WF/swf.d/run/$run_id/history"; then
  echo "The workflow did not reach its end." >&2
  exit 1
fi
if [[ -n "$(ls -A "$WF/swf.d/run/$run_id/failed")" ]]; then
  echo "Some jobs failed: $(ls "$WF/swf.d/run/$run_id/failed")" >&2
  exit 1
fi
echo "Local dry run OK"
