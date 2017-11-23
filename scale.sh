#!/usr/bin/bash

set -e

set -x
oc whoami
oc project
set +x

# dry-run mode?
dry_run=$(python3 -c 'import os; print(os.environ.get("DRY_RUN", "false").lower() in ("true", "1", "yes"))')

while true; do
    # get number of messages in the given queue
    read msg_count replicas <<< $(./sqs_status.py -q ${SQS_QUEUE_NAME})

    echo "[$(date -u)] Number of messages in ${DEPLOYMENT_PREFIX}_{${SQS_QUEUE_NAME}} is ${msg_count}. Replicas needed: ${replicas}."

    if [ "$dry_run" == "True" ]; then
        echo "[DRY-RUN] oc -n ${OC_PROJECT} scale --replicas=${replicas} dc ${DC_NAME}"
    else
        set -x
        oc -n ${OC_PROJECT} scale --replicas=${replicas} dc ${DC_NAME}
        set +x
    fi

    date -u +%s > /var/lib/f8a-scaler/liveness
    sleep ${SLEEP_INTERVAL}m
done
