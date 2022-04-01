#!/usr/bin/env bash
set -x

source ./common.sh

CR=api-load-crd.yaml

log "###############################################"
log "Workload: ${WORKLOAD}"
log "###############################################"

run_workload ${CR}

if [[ ${ENABLE_SNAPPY_BACKUP} == "true" ]] ; then
  snappy_backup api-load-${WORKLOAD}
fi
log "Finished workload ${0}"
