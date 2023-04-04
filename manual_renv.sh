#!/bin/bash

git pull
. /projects/epimodel/spack/share/spack/setup-env.sh
spack load r@4.2.1
Rscript -e "renv::init(bare = TRUE)"
Rscript -e "renv::restore()"
