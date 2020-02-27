#!/bin/bash -ex

${KUBECTL} delete --ignore-not-found -f ${local_manifest}

# Set debug verbosity level for logs when using cluster-sync
sed "s#--v=production#--v=debug#" ${local_manifest} | ${KUBECTL} create -f -

function getDesiredNumberScheduled {
        echo $(${KUBECTL} get daemonset $1 -o=jsonpath='{.status.desiredNumberScheduled}')
}

function getNumberAvailable {
        numberAvailable=$(${KUBECTL} get daemonset $1 -o=jsonpath='{.status.numberAvailable}')
        echo ${numberAvailable:-0}
}

function isOk {
        desiredNumberScheduled=$(getDesiredNumberScheduled $1)
        numberAvailable=$(getNumberAvailable $1)


        if [ "$desiredNumberScheduled" == "$numberAvailable" ]; then
          echo "$1 DS is ready"
          return 0
        else
          return 1
        fi
}

for i in {300..0}; do
    # We have to re-check desired number, sometimes takes some time to be filled in
    if isOk ignition-server; then
       break
    fi

    if [ $i -eq 0 ]; then
        echo "ignition-server DS haven't turned ready within the given timeout"
    exit 1
    fi


    sleep 1
done
