#!/bin/bash

set -exo pipefail

setup(){
    if [[ -z $PROW_JOB_ID ]]; then
        export job_id=${AIRFLOW_CTX_DAG_ID}
        export execution_date=${AIRFLOW_CTX_EXECUTION_DATE}
        export job_run_id=${AIRFLOW_CTX_DAG_RUN_ID}
        export ci="AIRFLOW"
        printenv
        # Get Airflow URL
        export airflow_base_url="http://$(kubectl get route/airflow -n airflow -o jsonpath='{.spec.host}')"
        # Setup Kubeconfig
        export KUBECONFIG=/home/airflow/auth/config
        curl -sS https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz | tar xz oc
        export PATH=$PATH:/home/airflow/.local/bin:$(pwd)
    else [[ -z $AIRFLOW_CTX_DAG_ID ]]
        export ci="PROW"
        export prow_base_url="https://prow.ci.openshift.org/view/gs/origin-ci-test/logs"
    fi
    # Generate a uuid
    export UUID=${UUID:-$(uuidgen)}
    # Elasticsearch Config
    export ES_SERVER=$ES_SERVER
    export ES_INDEX=$ES_INDEX
    # Get OpenShift cluster details
    cluster_name=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}') || echo "Cluster Install Failed"
    cluster_version=$(oc version -o json | jq -r '.openshiftVersion') || echo "Cluster Install Failed"
    network_type=$(oc get network.config/cluster -o jsonpath='{.status.networkType}') || echo "Cluster Install Failed"
    platform=$(oc get infrastructure cluster -o jsonpath='{.status.platformStatus.type}') || echo "Cluster Install Failed"
    cluster_type=""
    if [ "$platform" = "AWS" ]; then
        cluster_type=$(oc get infrastructure cluster -o jsonpath='{.status.platformStatus.aws.resourceTags[?(@.key=="red-hat-clustertype")].value}') || echo "Cluster Install Failed"
    fi
    if [ -z "$cluster_type" ]; then
        cluster_type="self-managed"
    fi

    masters=$(oc get nodes -l node-role.kubernetes.io/master --no-headers=true | wc -l) || true
    workers=$(oc get nodes -l node-role.kubernetes.io/worker --no-headers=true | wc -l) || true
    infra=$(oc get nodes -l node-role.kubernetes.io/infra --no-headers=true | wc -l) || true
    worker_type=$(oc get nodes -l node-role.kubernetes.io/worker -o jsonpath='{.items[].metadata.labels.beta\.kubernetes\.io/instance-type}') || true
    infra_type=$(oc get nodes -l node-role.kubernetes.io/infra -o jsonpath='{.items[].metadata.labels.beta\.kubernetes\.io/instance-type}') || true
    master_type=$(oc get nodes -l node-role.kubernetes.io/master -o jsonpath='{.items[].metadata.labels.beta\.kubernetes\.io/instance-type}') || true
    all=$(oc get nodes  --no-headers=true | wc -l) || true
}

index_task(){
    url=$1
    curl --insecure -X POST -H "Content-Type: application/json" -H "Cache-Control: no-cache" -d '{
        "ciSystem" : "'$ci'",
        "uuid" : "'$UUID'",
        "releaseStream": "'$RELEASE_STREAM'",
        "platform": "'$platform'",
        "clusterType": "'$cluster_type'",
        "masterNodesCount": '$masters',
        "workerNodesCount": '$workers',
        "infraNodesCount": '$infra',
        "masterNodesType": "'$master_type'",
        "workerNodesType": "'$worker_type'",
        "infraNodesType": "'$infra_type'",
        "totalNodesCount": '$all',
        "clusterName": "'$cluster_name'",
        "ocpVersion": "'$cluster_version'",
        "networkType": "'$network_type'",
        "buildTag": "'$task_id'",
        "nodeName": "'$HOSTNAME'",
        "jobStatus": "'$state'",
        "buildUrl": "'$build_url'",
        "upstreamJob": "'$job_id'",
        "upstreamJobBuild": "'$job_run_id'",
        "executionDate": "'$execution_date'",
        "jobDuration": "'$duration'",
        "startDate": "'"$start_date"'",
        "endDate": "'"$end_date"'",
        "timestamp": "'"$start_date"'"
        }' "$url"
}

set_duration(){
    start_date="$1"
    end_date="$2"
    if [[ -z $start_date ]]; then
        start_date=$end_date
    fi

    if [[ -z $start_date || -z $end_date ]]; then
        duration=0
    else
        end_ts=$(date -d "$end_date" +%s)
        start_ts=$(date -d "$start_date" +%s)
        duration=$(( $end_ts - $start_ts ))
    fi
}


index_tasks(){
    if [[ -z $PROW_JOB_ID ]]; then
        task_states=$(AIRFLOW__LOGGING__LOGGING_LEVEL=ERROR  airflow tasks states-for-dag-run $job_id $execution_date -o json)
        task_json=$( echo $task_states | jq -c ".[] | select( .task_id == \"$TASK\")")
        state=$(echo $task_json | jq -r '.state')
        task_id=$(echo $task_json | jq -r '.task_id')

        if [[ $task_id == "$AIRFLOW_CTX_TASK_ID" || $task_id == "cleanup" ]]; then
            echo "Index Task doesn't index itself or cleanup step, skipping."
        else
            start_date=$(echo $task_json | jq -r '.start_date')
            end_date=$(echo $task_json | jq -r '.end_date')
            set_duration "$start_date" "$end_date"
            encoded_execution_date=$(python3 -c "import urllib.parse; print(urllib.parse.quote(input()))" <<< "$execution_date")
            build_url="${airflow_base_url}/task?dag_id=${job_id}&task_id=${task_id}&execution_date=${encoded_execution_date}"
            index_task "$ES_SERVER/$ES_INDEX/_doc/$job_id%2F$job_run_id%2F$task_id"
        fi
    else
        task_id=$BUILD_ID
        job_id=$JOB_NAME
        job_run_id=$PROW_JOB_ID
        state=$JOB_STATUS
        build_url="${prow_base_url}/${job_id}/${task_id}"
        set_duration "$JOB_START" "$JOB_END"
        index_task "$ES_SERVER/$ES_INDEX/_doc/$job_id%2F$job_run_id%2F$task_id"
    fi
}

# Defaults
if [[ -z $PROW_JOB_ID && -z $AIRFLOW_CTX_DAG_ID ]]; then
    echo "Not a CI run. Skipping CI metrics to be indexed"
    exit 0
fi
if [[ -z $ES_SERVER ]]; then
  echo "Elastic server is not defined, please check"
  exit 1
fi

if [[ -z $ES_INDEX ]]; then
  export ES_INDEX=perf_scale_ci
fi

setup
index_tasks