#!/bin/sh
. ../environment.sh
terraform init \
  -backend-config="bucket=${TF_VAR_gcs_tf_bucket}" \
  -backend-config="prefix=on-premises-k8s-cluster"
