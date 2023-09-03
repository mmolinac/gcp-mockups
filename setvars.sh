#!/bin/bash
## Functions
check_binaries() {
    local mybinaries="terraform gcloud gsutil" errcode=0
    for onebin in ${mybinaries}
    do
        which $onebin > /dev/null || errcode=1
    done
    return $errcode
}

show_usage()
{
    echo "Usage: $0 <dev-proj-id> <prod-proj-id> <gcp-region>"
    echo " "
    echo "Where: <dev-proj-id>  is the ID from your GCP project list"
    echo "                      you want for development."
    echo "       <prod-proj-id> is the ID from your GCP project"
    echo "                      list you want for Production. Also, you'll"
    echo "                      have your DNS zone there"
    echo "Where: <gcp-region>   is the GCP region name of your choice."
    echo " "
    echo "Example:"
    echo "  $0 development-123456 production-123456 europe-southwest1"
    echo " "
}

create_env_script()
{
    local devproj="$1" prodproj="$2" gcregion="$3"
    if [ -f .gcs_tf_bucket ]; then
        mybucketname=`cat .gcs_tf_bucket| head -1`
    else
        # We need to create the bucket ourselves
        echo "Creating TF state bucket ..."
        for i in `seq 1 40`
        do
            rprefix=`echo $RANDOM | md5sum | head -c 5`
            mybucketname="gcp-mockups-${rprefix}-tf-state"
            if gsutil mb -l ${gcregion} -p ${devproj} gs://${mybucketname} 2>&1 > /dev/null ; then
                # We have a bucket
                echo "Created gs://${mybucketname} on region ${gcregion} and project ${devproj} ..."
                echo "${mybucketname}" > .gcs_tf_bucket
                gsutil versioning set on gs://${mybucketname}
                break
            else
                # We failed
                mybucketname=""
            fi
        done
        if [ "$mybucketname" == "" ]; then
            echo "Unable to create a valid bucket."
            exit 1
        fi
    fi
    cat > environment.sh << EOF
#!/bin/sh
export TF_VAR_dev_proj_id="${devproj}"
export TF_VAR_prod_proj_id="${prodproj}"
export TF_VAR_gcp_region_id="${gcregion}"
export TF_VAR_gcp_zone_id="${gcregion}-a"
export TF_VAR_gcs_tf_bucket="${mybucketname}"
EOF
    chmod u+x environment.sh
}

## Main block
if [ "$#" -ne 3 ]; then
  show_usage
  exit 1
else
  if check_binaries; then
    create_env_script $1 $2 $3
  else
    echo "You must install Google Cloud SDK and Terraform."
    exit 1
  fi
fi
