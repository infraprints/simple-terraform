#!/bin/bash
set -e
DIR="$(dirname $( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd ))"

PLAN_NAME="infra.tfplan"
TERRAFORM="terraform.tf"
FILE_BACKEND="backend.hcl"
FILE_EXEC_SET="tasks.log"
FILE_NO_RUN="IGNORE"

init() {
    if [ -z ${TF_STATE_REGION+x} ]; then echo "env:TF_STATE_REGION is not yet. This is necessary for Terraform Pipelines."; exit 1; fi
    if [ -z ${TF_STATE_BUCKET+x} ]; then echo "env:TF_STATE_BUCKET is not yet. This is necessary for Terraform Pipelines."; exit 1; fi
    if [ -z ${TF_STATE_DYNAMO_TABLE+x} ]; then echo "env:TF_STATE_DYNAMO_TABLE is not yet. This is necessary for Terraform Pipelines."; exit 1; fi
    if [ -z ${TF_ENVIRONMENT+x} ]; then echo "env:TF_ENVIRONMENT is not yet. This is necessary for Terraform Pipelines."; exit 1; fi

    curr=$(pwd)
    key="${curr#"${DIR}/"}"
    echo "" > "${FILE_BACKEND}"
    echo "region         = \"${TF_STATE_REGION}\""          >> "${FILE_BACKEND}"
    echo "bucket         = \"${TF_STATE_BUCKET}\""          >> "${FILE_BACKEND}"
    echo "dynamodb_table = \"${TF_STATE_DYNAMO_TABLE}\""    >> "${FILE_BACKEND}"
    echo "key            = \"${key}/terraform.tfstate\""    >> "${FILE_BACKEND}"
    echo "encrypt        = true"                            >> "${FILE_BACKEND}"

    terraform init -input=false -no-color -backend=true -backend-config="$FILE_BACKEND"
}

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
        find . -name "${TERRAFORM}" -exec sh -c '(cd $(dirname {}) && export COUNTER=$(cat ORDER 2>/dev/null || echo 0) && echo ${COUNTER}%{})' \; > "${FILE_EXEC_SET}"
        cat "${FILE_EXEC_SET}" | sort -n | while read file_comp; do
            order="$(cut -d'%' -f1 <<< ${file_comp})"
            component_path="$(cut -d'%' -f2 <<< ${file_comp})"
            component="$(basename "$(dirname "$component_path")")"
            namespace="$(dirname "$component_path")"
            namespace="${namespace#"./"}"
            scope="${TF_ENVIRONMENT}:${order}:${namespace}"
            
            echo "[${TF_ENVIRONMENT}:${order}]: Discovered component '${component}' at ${namespace}"
            (
                cd "${namespace}"
                if [ -f "${FILE_NO_RUN}" ]; then
                    echo "[$scope]: Ignore file detected. Ignoring."
                    exit
                fi
                
                echo "[$scope]: Initializing"
                init
 
                echo "[$scope]: Emitting providers "
                terraform providers -v
                
                terraform plan -input=false -no-color -out="$PLAN_NAME"
            )
        done
    )
}

main