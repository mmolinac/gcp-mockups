# On-premises Kubernetes cluster
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
