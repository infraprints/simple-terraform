#!/bin/bash
set -e
# DIR="$(dirname $( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd ))"

PLAN_NAME="infra.tfplan"
FILE_BACKEND="backend.hcl"
FILE_NO_PLAN="NO_PLAN"
FILE_PLAN_SET="plans.log"
FILE_NO_RUN="IGNORE"

main() {
    ## Init
    echo "[INFO]: Starting terraform pipeline"

    ## System
    DIR_ENV="${CODEBUILD_SRC_DIR_plan}/environments"
    DIR_STAGE="${DIR_ENV}/${TF_ENVIRONMENT}"

    echo "[INFO]: Entering environment $TF_ENVIRONMENT"
    echo "[$TF_ENVIRONMENT]: Preparing to run"
    (
        cd "$DIR_STAGE"
        find . -name "${PLAN_NAME}" -exec sh -c '(cd $(dirname {}) && export COUNTER=$(cat ORDER 2>/dev/null || echo 0) && echo ${COUNTER}%{})' \; > "${FILE_PLAN_SET}"
        cat "${FILE_PLAN_SET}" | sort -n | while read file_comp; do
            order="$(cut -d'%' -f1 <<< ${file_comp})"
            component_path="$(cut -d'%' -f2 <<< ${file_comp})"
            component="$(basename "$(dirname "$component_path")")"
            namespace="$(dirname "$component_path")"
            namespace=${namespace#"./"}
            scope="${TF_ENVIRONMENT}:${order}:${namespace}"

            echo "[${TF_ENVIRONMENT}:${order}]: Discovered plan for '${component}' at ${namespace}"
            (
                cd "${namespace}"
                if [ -f "${FILE_NO_RUN}" ]; then
                    echo "[$scope]: Ignore file detected. Ignoring."
                    exit
                fi

                if [ -f "${FILE_NO_PLAN}" ]; then
                    echo "[$scope]: Applying from scratch"
                    terraform apply -auto-approve -input=false -no-color
                else
                    echo "[$scope]: Applying plan $PLAN_NAME"
                    terraform apply -auto-approve -input=false -no-color "$PLAN_NAME"
                fi
            )
        done
    )
}

main