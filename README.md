# Test Workflow for `slurmworkflow`

This repo is create a workflow testing
[`slurmworkflow`](https://github.com/EpiModel/slurmworkflow)'s capabilities on
an HPC.

## How To Use

1. run `renv::init()`
2. run the "R/00-setup_pacakges.R" file to install `slurmworkflow`
3. run `renv::snapshot()`
4. commit and push the changes with git

5. edit the "R/workflow_01-test.R" to fit your HPC setup
6. run the "R/workflow_01-test.R" file
7. send the workflow directory to the hpc
8. run the workflow on the HPC



