# ocm-api-load e2e benchmarks

In order to kick off one of these benchmarks you must use the run.sh script.

Running from CLI:

```sh
$WORKLOAD=list-clusters GATEWAY_URL="http://localhost:8080" OCM_TOKEN="notARealToken" RATE=10/s AWS_ACCESS_KEY="empty" AWS_ACCESS_SECRET="empty" AWS_ACCOUNT_ID="empty" ./run.sh
```


There are 13 different workloads at the moment, that could be launched as follows:

- **`list-clusters`**: `WORKLOAD=list-clusters ./run.sh`
- **`self-access-token`**: `WORKLOAD=self-access-token ./run.sh`
- **`list-subscriptions`**: `WORKLOAD=list-subscriptions ./run.sh`
- **`access-review`**: `WORKLOAD=access-review ./run.sh`
- **`register-new-cluster`**: `WORKLOAD=register-new-cluster ./run.sh`
- **`register-existing-cluster`**: `WORKLOAD=register-existing-cluster ./run.sh`
- **`create-cluster`**: `WORKLOAD=create-cluster ./run.sh`
- **`get-current-account`**: `WORKLOAD=get-current-account ./run.sh`
- **`quota-cost`**: `WORKLOAD=quota-cost ./run.sh`
- **`resource-review`**: `WORKLOAD=resource-review ./run.sh`
- **`cluster-authorizations`**: `WORKLOAD=cluster-authorizations ./run.sh`
- **`self-terms-review`**: `WORKLOAD=self-terms-review ./run.sh`
- **`certificates`**: `WORKLOAD=certificates ./run.sh`

## Environment variables

Workloads can be tweaked with the following environment variables:


| Variable         | Description                         | Default |
|------------------|-------------------------------------|---------|
| **OPERATOR_REPO**    | Benchmark-operator repo         | https://github.com/cloud-bulldozer/benchmark-operator.git      |
| **OPERATOR_BRANCH**  | Benchmark-operator branch       | master  |
| **ES_SERVER**        | Elasticsearch endpoint          | https://search-perfscale-dev-chmf5l4sh66lvxbnadi4bznl3a.us-west-2.es.amazonaws.com:443|
| **ES_INDEX**         | Elasticsearch index             | ripsaw-kube-burner|
| **TEST_TIMEOUT**        | Benchmark timeout, in seconds | 7200 (2 hours) |
| **TEST_CLEANUP**        | Remove benchmark CR at the end | true |
| **GATEWAY_URL**      | Gateway url to perform the test against       | "https://api.integration.openshift.com |
| **OCM_TOKEN**| OCM Authorization token |  |
| **AWS_ACCESS_KEY**    | AWS access key          |  |
| **AWS_ACCESS_SECRET**              | AWS access secret                     |       |
| **AWS_ACCOUNT_ID**            | AWS Account ID, is the 12-digit account number |       |
| **RATE**| Rate of the attack. Format example 5/s | 10/s |
| **DURATION**         | Duration of each individual run in minutes | 1 |
| **OUTPUT_PATH** | Output directory for result and report files | /tmp/results |
| **COOLDOWN**         | Cooldown time between tests in seconds | 10 |
| **SLEEP**   |  | 5 |
| **WORKLOAD** | Test name | list-clusters |

**Note**: You can use basic authentication for ES indexing using the notation `http(s)://[username]:[password]@[host]:[port]` in **ES_SERVER**.


### Snappy integration configurations

To backup data to a given snappy data-server

#### Environment Variables

**`ENABLE_SNAPPY_BACKUP`**
Default: ''
Set to true to backup the logs/files generated during a workload run

**`SNAPPY_DATA_SERVER_URL`**
Default: ''
The Snappy data server url, where you want to move files.

**`SNAPPY_DATA_SERVER_USERNAME`**
Default: ''
Username for the Snappy data-server.

**`SNAPPY_DATA_SERVER_PASSWORD`**
Default: ''
Password for the Snappy data-server.

**`SNAPPY_USER_FOLDER`**
Default: 'perf-ci'
To store the data for a specific user.
