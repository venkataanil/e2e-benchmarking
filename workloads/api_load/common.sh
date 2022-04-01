#!/usr/bin/env bash

source env.sh
source ../../utils/common.sh
source ../../utils/benchmark-operator.sh

openshift_login

export_defaults() {
  network_type=$(oc get network cluster -o jsonpath='{.status.networkType}' | tr '[:upper:]' '[:lower:]')
  export UUID=$(uuidgen)
  export CLUSTER_NAME=$(oc get infrastructure cluster -o jsonpath="{.status.infrastructureName}")
  local baremetalCheck=$(oc get infrastructure cluster -o json | jq .spec.platformSpec.type)
  zones=($(oc get nodes -l node-role.kubernetes.io/workload!=,node-role.kubernetes.io/infra!=,node-role.kubernetes.io/worker -o go-template='{{ range .items }}{{ index .metadata.labels "topology.kubernetes.io/zone" }}{{ "\n" }}{{ end }}' | uniq))
  platform=$(oc get infrastructure cluster -o jsonpath='{.status.platformStatus.type}' | tr '[:upper:]' '[:lower:]')
  #Check to see if the infrastructure type is baremetal to adjust script as necessary 
  if [[ "${baremetalCheck}" == '"BareMetal"' ]]; then
    log "BareMetal infastructure: setting isBareMetal accordingly"
    isBareMetal=true
  else
    isBareMetal=false
  fi

  if [[ "${isBareMetal}" == "true" ]]; then
    #Installing python3.8
    sudo yum -y install python3.8
  fi
}

deploy_operator() {
  deploy_benchmark_operator ${OPERATOR_REPO} ${OPERATOR_BRANCH}
  oc adm policy -n benchmark-operator add-scc-to-user privileged -z benchmark-operator
}

run_workload() {
  log "Deploying benchmark"
  local TMPCR=$(mktemp)
  envsubst < $1 > ${TMPCR}
  run_benchmark ${TMPCR} ${TEST_TIMEOUT}
  local rc=$?
  if [[ ${TEST_CLEANUP} == "true" ]]; then
    log "Cleaning up benchmark"
    kubectl delete -f ${TMPCR}
  fi
  return ${rc}
}


snappy_backup(){
  log "Snappy server as backup enabled"
  source ../../utils/snappy-move-results/common.sh
  csv_list=`find . -name "*.csv"` 
  mkdir -p files_list
  cp $csv_list ./files_list
  tar -zcf snappy_files.tar.gz ./files_list
  local snappy_path="${SNAPPY_USER_FOLDER}/${runid}${platform}-${cluster_version}-${network_type}/${1}/${folder_date_time}/"
  generate_metadata > metadata.json  
  ../../utils/snappy-move-results/run_snappy.sh snappy_files.tar.gz $snappy_path
  ../../utils/snappy-move-results/run_snappy.sh metadata.json $snappy_path
  store_on_elastic
  rm -rf files_list
}

export_defaults
deploy_operator
