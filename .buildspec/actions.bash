#!/bin/bash
set -e

PLAN_NAME="infra.tfplan"

main() {
    ## Init
    DIR="$(dirname $( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd ))"
    echo "[INFO]: Starting terraform pipeline"

    ## Args
    stage="$1"
    
    ## System
    DIR_ENV="${DIR}/environments"
    DIR_STAGE="${DIR_ENV}/${stage}"

    echo "[INFO]: Entering environment $stage"
    echo "[$stage]: Preparing to run"
    (
        cd "$DIR_STAGE"
        for component in *; do
            if [ ! -d "${component}" ]; then
                continue
            fi

            DIR_COMPONENT="${DIR_STAGE}/${component}"
            echo "[$stage]: Discovered component '${component}' at ${DIR_COMPONENT}"
            (
                scope="${stage}:${component}"
                cd "${component}"

                echo "[$scope]: Initializing"
                terraform init -input=false -no-color
                echo "[$scope]: Emitting providers "
                terraform providers -v
                
                terraform plan -input=false -no-color -out="$PLAN_NAME"
            )
        done
    )
}

TF_ENVIRONMENT="dev"
main "$TF_ENVIRONMENT"