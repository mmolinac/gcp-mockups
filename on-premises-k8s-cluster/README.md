# On-premises Kubernetes cluster
In this mockup we'll spawn three servers of `e2-standard-2` type.

This will be an unmanaged instance group and we'll add a metadata script to perform these initial ations:
- Add the official Kubernetes repository and install the basic packages
- Create the unmanaged instance group
- Create a load balancer on top of these instance, if needed, for ports tcp/80 and tcp/443 .

Additional features:
- You'll have the tools to create, manage and maintain the on-premises cluster.
- The cluster *won't* be built. You have to do it.

## Initialize stack
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

## Start stack
To create or turn on the stack, you have to:

```Shell
$ ./apply.sh 
Reading required version from terraform file
Reading required version from constraint: >= 1.4
Matched version: 1.5.6
Switched terraform to version "1.5.6" 

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following
symbols:
  + create
...
...
```
Just answer `yes` when asked to.

## Log in to compute hosts
We'll log in through:
```Shell
$ gcloud compute ssh onpremclust00
WARNING: The private SSH key file for gcloud does not exist.
WARNING: The public SSH key file for gcloud does not exist.
WARNING: You do not have an SSH key for gcloud.
WARNING: SSH keygen will be executed to generate a key.
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
...
...
```
And off you go.

## Turn off hosts
When you're not using them, you can just turn them off temporarily by doing:
```Shell
$ ./apply.sh off
...
```
It will stop the hosts, so the compute expense will be zero.

## Destroy the stack
You have to issue this:
```Shell
$ ./destroy.sh 
Reading required version from terraform file
Reading required version from constraint: >= 1.4
Matched version: 1.5.6
Switched terraform to version "1.5.6" 
...
...

Plan: 0 to add, 0 to change, 6 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: 
```
Enter `yes` and that will be all.
