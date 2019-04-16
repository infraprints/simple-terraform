#!/bin/bash
set -e
DIR="$(dirname $( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd ))"

PLAN_NAME="infra.tfplan"
FILE_BACKEND="backend.hcl"

main() {
    ## Init
    echo "[INFO]: Starting terraform pipeline"
    
    ## System
    DIR_ENV="${DIR}/environments"
    DIR_STAGE="${DIR_ENV}/${TF_ENVIRONMENT}"

    echo "[INFO]: Entering environment $TF_ENVIRONMENT"
    echo "[$TF_ENVIRONMENT]: Preparing to run"
    (
        cd "$DIR_STAGE"
        find . -name "${PLAN_NAME}" | while read file_comp; do
            echo $file_comp
            component="$(basename "$(dirname "$file_comp")")"
            namespace="$(dirname "$file_comp")"
            namespace=${namespace#"./"}
            scope="${TF_ENVIRONMENT}:${namespace}"
            
            echo "[$TF_ENVIRONMENT]: Discovered plan for '${component}' at ${namespace}"
            (
                cd "${namespace}"
 
                echo "[$scope]: Apply"                
                terraform apply -auto-approve -input=false -no-color "$PLAN_NAME"
            )
        done
    )
}

main