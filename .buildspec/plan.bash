#!/bin/bash
set -e
DIR="$(dirname $( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd ))"

PLAN_NAME="infra.tfplan"
FILE_BACKEND="backend.hcl"

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
        find . -name "terraform.tf" | while read file_comp; do
            echo $file_comp
            component="$(basename "$(dirname "$file_comp")")"
            namespace="$(dirname "$file_comp")"
            namespace=${namespace#"./"}
            scope="${TF_ENVIRONMENT}:${namespace}"
            
            echo "[$TF_ENVIRONMENT]: Discovered component '${component}' at ${namespace}"
            (
                cd "${namespace}"
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