#!/bin/sh

cd "$(dirname "$0")"
puppet apply --modulepath=modules --hiera_config=hiera.yaml manifests/init.pp
