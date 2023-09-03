#!/bin/sh
. ../environment.sh
`which tfswitch`
if [ "$1" == "off" ]; then
  echo "We'll turn off the compute instances"
  export TF_VAR_onprem_instance_status=TERMINATED
else
  export TF_VAR_onprem_instance_status=RUNNING
fi
terraform apply
