# gcp-mockups
Toolset for quickly create and destroy different mockups for personal use on GCP

## Requirements
The common requirements for all mockups are the following:
- A valid GCP account where you are already logged in. More directions to do that below.
- [Google Cloud SDK](https://cloud.google.com/sdk) already installed and available.
- [Terraform](https://www.terraform.io/) or [tfswitch](https://tfswitch.warrensbox.com/) installed and available.

Regarding your GCP account, if you have not already, please log in by doing:
```Shell
$ gcloud auth login
```

Once you've logged in, you must also provide [application default credentials](https://cloud.google.com/docs/authentication/application-default-credentials) by doing:
```Shell
$ gcloud auth application-default login
```

Now we're going to assume that you have (at least) two projects:
- Development project
- Production project

I'm going to use the Development project for all mockups.

If you **already** have one GCS bucket for Terraform state already created, please do:
```Shell
$ echo "mybucketname" > .gcs_tf_bucket
```
**Otherwise, it will be created for you**

Now, please go ahead, chose the projects and region you want to use:
```Shell
$ gcloud projects list
PROJECT_ID          NAME         PROJECT_NUMBER
development-123456  development  111122223333
production-123456   production   4444555566
```
And now proceed once to set the environment this way:
```Shell
$ ./setvars.sh development-123456 production-123456 europe-southwest1
$ source environment.sh
```

## Mockups
The different mockups (one per folder) have a different purpose. See a list of them below:

- [on-premises-k8s-cluster](on-premises-k8s-cluster/)

