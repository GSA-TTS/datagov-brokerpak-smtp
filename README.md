# smtp-brokerpak

## Why this project

The SMTP brokerpak is a
[cloud-service-broker](https://github.com/pivotal/cloud-service-broker) plugin
that makes AWS SES brokerable via the [Open Service Broker API](https://www.openservicebrokerapi.org/) (compatible with Cloud Foundry and Kubernetes), using Terraform. The brokered service can be used to send transactional mail.

For more information about the brokerpak concept, here's a [5-minute lightning
talk](https://www.youtube.com/watch?v=BXIvzEfHil0) from the 2019 Cloud Foundry Summit. You may also want to check out the brokerpak
[introduction](https://github.com/pivotal/cloud-service-broker/blob/master/docs/brokerpak-intro.md)
and
[specification](https://github.com/pivotal/cloud-service-broker/blob/master/docs/brokerpak-specification.md)
docs.

Huge props go to @josephlewis42 of Google for publishing and publicizing the
brokerpak concept, and to the Pivotal team running with the concept!


## Features/components

Each brokered AWS SES instance provides:

- If no domain is specified
  - SMTP credentials for sending mail from an auto-generated subdomain (suitable for development)
  - Bounce, Complaint, and Delivery notifications can be sent to your server. See [Delivery Notifications](#delivery-notifications) for instructions
- If a domain is specified
  - SMTP credentials for sending mail from the supplied domain
  - DNS records necessary for verifying domain ownership (TXT and DKIM)
  - Bounce, Complaint, and Delivery notifications can be sent to your server. See [Delivery Notifications](#delivery-notifications) for instructions

### IP-limited security credentials

The credentials created by the bind operation sets a condition on the IAM policy that limits the IP addresses that may use the credential. By default, this gets set to the egress IP addresses for cloud.gov.

To create a service key that will be valid from IP 1.2.3.4:

`cf create-service-key smtp-instance-name service-key-name -c '["source_ips": ["1.2.3.4/32"]]'`

Or in terraform to set to a variable:

```
resource "cloudfoundry_service_key" "smtp_key" {
  name             = local.key_name
  service_instance = data.cloudfoundry_service_instance.smtp_email.id
  params_json = jsonencode({
    source_ips = [var.source_ip]
  })
}
```

More information about source ip conditions can be found in these documents:

* https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_aws_deny-ip.html
* https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html#condition-keys-sourceip
* https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_multi-value-conditions.html#reference_policies_multi-key-or-value-conditions

### Custom MAIL FROM

The broker can set up a [custom MAIL FROM](https://docs.aws.amazon.com/ses/latest/dg/mail-from.html) by passing in the `mail_from_subdomain` variable value.

This should just be the subdomain that mail will appear to be coming from and will be prepended to your given `domain`.

The provision outputs will include the required DNS records to validate this setting in the `required_records` output.

### Delivery Notifications

[SES Delivery Notifications](https://docs.aws.amazon.com/ses/latest/dg/monitor-sending-activity-using-notifications-sns.html) can be configured by:

1. Add `"enable_feedback_notifications": true` to the provisioning parameters
2. Add `"notification_webhook": "HTTPS_WEBHOOK_ENDPOINT"` to the bind parameters.

* The webhook must be an HTTPS endpoint, accessible to the internet.
* [Documentation on message contents](https://docs.aws.amazon.com/ses/latest/dg/notification-contents.html)
* **Important** the endpoint must be ready to [confirm the subscription](https://docs.aws.amazon.com/sns/latest/dg/SendMessageToHttp.confirm.html) during the bind process. Here is [an example](https://github.com/GSA/notifications-api/blob/d83a4331263d434ba1415ce652ed70737acd5e9f/app/notifications/sns_handlers.py#L51) of the confirmation process.

Example manifest.yml:
```
services:
  - name: smtp-service
    parameters:
      notification_webhook: https://my.server.gov/notifications/ses
```

Included in the bind credentials will be the Amazon ARNs for `bounce_topic_arn`, `complaint_topic_arn`, and `delivery_topic_arn`. These can be used to
validate the incoming webhooks as coming from the correct source, and help determine between the three message types your webhook will be receiving. They can
be ignored if you are not using the feedback notifications.


## Development Prerequisites

1. [Docker Desktop (for Mac or
Windows)](https://www.docker.com/products/docker-desktop) or [Docker Engine (for
Linux)](https://www.docker.com/products/container-runtime) is used for
building, serving, and testing the brokerpak.
1. [Access to the GitHub Container
   Registry](https://docs.github.com/en/packages/guides/migrating-to-github-container-registry-for-docker-images#authenticating-with-the-container-registry).
   (We are working on making the necessary container image publicly accessible;
   this step should not be necessary in future.)

1. `make` is used for executing docker commands in a meaningful build cycle.
1. [`checkdmarc`](https://pypi.org/project/checkdmarc/) is used to verify the DMARC and SPF configuration of configured instances
1. AWS account credentials (as environment variables) are used for actual
   service provisioning. The corresponding user must have at least the permissions described in `permission-policies.tf`. Set at least these variables:

    - AWS_ACCESS_KEY_ID
    - AWS_SECRET_ACCESS_KEY
    - AWS_DEFAULT_REGION


## Developing the brokerpak
Run the `make` command by itself for information on the various targets that are available. Notable targets are described below

```
$ make
clean      Bring down the broker service if it's up, clean out the database, and remove created images
build      Build the brokerpak(s) and create a docker image for testing it/them
up         Run the broker service with the brokerpak configured. The broker listens on `0.0.0.0:8080`. curl http://127.0.0.1:8080 or visit it in your browser.
test       Execute the brokerpak examples against the running broker
down       Bring the cloud-service-broker service down
all        Clean and rebuild, then bring up the server, run the examples, and bring the system down
help       This help
```


### Running the brokerpak
Run
```
make build up
```
The broker will start and listen on `0.0.0.0:8080`. You
test that it's responding by running:
```
curl -i -H "X-Broker-API-Version: 2.16" http://user:pass@127.0.0.1:8080/v2/catalog
```
In response you will see a YAML description of the services and plans available
from the brokerpak.

(Note that the `X-Broker-API-version` header is [**required** by the OSBAPI
specification](https://github.com/openservicebrokerapi/servicebroker/blob/master/spec.md#headers).
The broker will reject requests that don't include the header with `412
Precondition Failed`, and browsers will show that status as `Not Authorized`.)

You can also inspect auto-generated documentation for the brokerpak's offerings
by visiting [`http://127.0.0.1:8080/docs`](http://127.0.0.1:8080/docs) in your browser.

### Testing the brokerpak (while it's running)

Run
```
make test
```

The [examples specified by the
brokerpak](https://github.com/pivotal/cloud-service-broker/blob/master/docs/brokerpak-specification.md#service-yaml-flie)
will be invoked for end-to-end testing of the brokerpak's service offerings.

You can also manually interact with the broker using the `cloud-service-broker` CLI,
![image](https://user-images.githubusercontent.com/85196563/163099919-656fcb63-d6d1-4190-a023-48697a34906d.png)


### Shutting the brokerpak down

Run

```
make down
```

The broker will be stopped.

### Cleaning out the current state

Run
```
make clean
```
The built brokerpak files will be removed.


### Testing sending emails

Start the broker locally
```
make [clean build] up
```
Run the `send_email.py` script to send an email from the newly created SES service,
```
# pip install emails
python send_email.py <instance_name.binding.json> <email_recipient>
```

## Contributing

Check
out the list of [open issues](https://github.com/GSA/eks-brokerpak/issues) for
areas where you can contribute.

See [CONTRIBUTING](CONTRIBUTING.md) for additional information.

## Public domain

This project is in the worldwide [public domain](LICENSE.md). As stated in [CONTRIBUTING](CONTRIBUTING.md):

> This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
>
> All contributions to this project will be released under the CC0 dedication. By submitting a pull request, you are agreeing to comply with this waiver of copyright interest.
