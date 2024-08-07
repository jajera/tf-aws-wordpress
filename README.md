# tf-aws-wordpress

Work in progress!

## build

Prefix must exist first before anything else due to race condition.

```bash
terraform apply --auto-approve --target=random_string.suffix
```

```bash
terraform apply --auto-approve
```

## destroy

```bash
terraform destroy --auto-approve
```
