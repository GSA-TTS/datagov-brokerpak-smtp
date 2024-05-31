# How to iterate on the provisioning code

You can develop and test the Terraform code for provisioning in isolation from
the broker context here.

1. Copy `terraform.tfvars-template` to `terraform.tfvars`, then edit the content
   appropriately. In particular, set these parameters:
   - `instance_name` should be set to something unique to avoid collisions in the target AWS account!
   - `domain` should be an empty string if you want to run the full suite of Terraform resources including DNS records.
   - `default_domain` should be a domain name including one or more subdomains, such as `dev.ssb.notify.gov`

1. Set these three environment variables:

    - AWS_ACCESS_KEY_ID
    - AWS_SECRET_ACCESS_KEY
    - AWS_DEFAULT_REGION

1. In order to have a development environment consistent with other
   collaborators, we use a special Docker image with the exact CLI binaries we
   want for testing. Doing so will avoid [discrepancies we've noted between development under OS X and W10](https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1262#issuecomment-932792757).

   First, build the image:

    ```bash
    docker build -t smtp-provision:latest .
    ```

1. Then, start a shell inside a container based on this image. The parameters
   here carry some of your environment variables into that shell, and ensure
   that you'll have permission to remove any files that get created.

    ```bash
    docker run -v `pwd`:`pwd` -w `pwd` -e HOME=`pwd` --user $(id -u):$(id -g) -e TERM -it --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -e AWS_DEFAULT_REGION smtp-provision:latest
    ```

1. Within that container:
    ```bash
    terraform init
    terraform apply
    [tinker in your editor, run terraform apply, inspect the cluster, repeat]
    terraform destroy -auto-approve
    exit
    ```

## Troubleshooting

```
Error creating SES domain identity verification: Expected domain verification Success, but was in state Failed
```
This error occurs when [the timeout](https://github.com/GSA-TTS/datagov-brokerpak-smtp/blob/767bcb71179494a0578c018f8338df4711f1c4fc/terraform/provision/verification.tf#L61) to verify the domain identity is reached. This can be a DNS problem.

Ensure that the domain or subdomain you are working in is reachable by DNS. Ensure that the zone(s) above your subdomain have DNS records which point to your zone &mdash; for example if you are using a `default_domain` of `dev.ssb.notify.gov`, ensure that the DNS records at `ssb.notify.gov` correctly indicate a `dev` subdomain. It will need an NS and a DS record.
