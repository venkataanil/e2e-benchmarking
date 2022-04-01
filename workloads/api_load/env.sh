# Common

TEST_CLEANUP=${TEST_CLEANUP:-true}
export ES_SERVER=${ES_SERVER:-https://search-perfscale-dev-chmf5l4sh66lvxbnadi4bznl3a.us-west-2.es.amazonaws.com:443}
export ES_INDEX=ripsaw-api-load

# Benchark-operator
OPERATOR_REPO=${OPERATOR_REPO:-https://github.com/cloud-bulldozer/benchmark-operator.git}
OPERATOR_BRANCH=${OPERATOR_BRANCH:-master}

# Workload
export TEST_TIMEOUT=${TEST_TIMEOUT:-7200}

# api-load
export WORKLOAD=list-clusters
export GATEWAY_URL=${GATEWAY_URL}
export OCM_TOKEN=${OCM_TOKEN}
export DURATION=${DURATION:=1}
export RATE=${RATE:=1/s}
export OUTPUT_PATH=${OUTPUT_PATH:=/tmp/results}
export AWS_ACCESS_KEY=${AWS_ACCESS_KEY}
export AWS_ACCESS_SECRET=${AWS_ACCESS_SECRET}
export AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}
export COOLDOWN=${COOLDOWN:=10}
export SLEEP=${SLEEP:=5}
