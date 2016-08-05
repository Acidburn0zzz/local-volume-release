#!/bin/bash

set -e -x

scripts_path=./$(dirname $0)
eval $($scripts_path/get_paths.sh)

usage () {
    echo "Usage: run-pats admin_user admin_password api_host apps_domain test_application_path name_prefix"
    exit 1
}

if [[ "$#" -le 4 ]]
    then
        usage
fi

pushd `dirname $0`
    CONFIG=${PWD}/config
    mkdir -p ${CONFIG}
    CONFIG=${CONFIG}/pats.json

    set +e
    which cf
    if [ $? -eq 0 ]; then
      set -e
      echo "Skipping cf cli install"
    else
      set -e
      mkdir -p cf-cli
      pushd cf-cli
        curl -L "https://cli.run.pivotal.io/stable?release=linux64-binary&source=github" | tar -zx
        ln -s ${PWD}/cf /bin/cf
      popd
    fi

    echo "{
      \"admin_user\": \"$1\",
      \"admin_password\": \"$2\",
      \"api\": \"$3\",
      \"apps_domain\": \"$4\",
      \"skip_ssl_validation\": true,
      \"default_timeout\": 30,
      \"name_prefix\": \"$6\"
    } "  > ${CONFIG}

    export TEST_APPLICATION_PATH=$5

    pushd $PERSI_ACCEPTANCE_DIR/src/code.cloudfoundry.org/persi-acceptance-tests
        CONFIG=${CONFIG} ginkgo -p -r -v .
    popd
popd
