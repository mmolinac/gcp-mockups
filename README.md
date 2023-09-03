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
$ ./setenv.sh development-123456 production-123456 europe-southwest1
$ source environment.sh
```

## Mockups
The different mockups (one per folder) will have a different purpose. See a list of them below.

### On-premises Kubernetes cluster
In this mockup we'll spawn three servers of xxx size.
This will be an unmanaged instance group and we'll add a metadata script to perform these initial ations:
- Add the official Kubernetes repository and install the basic packages
- Create the unmanaged instance group
- Create a load balancer on top of these instance, if needed, for ports tcp/80 and tcp/443 .

Additional features:
- We'll log in through:
   ```Shell
   $ gcloud compute ssh <instancename>
   ```

To start using this mockup, please do this once:
```Shell
$ init.sh
Initializing the backend...

Successfully configured the backend "gcs"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Finding hashicorp/google versions matching "~> 4.80.0"...
- Installing hashicorp/google v4.80.0...
- Installed hashicorp/google v4.80.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```
