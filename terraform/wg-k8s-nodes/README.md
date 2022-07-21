
Terraforms wg configs for mesh network of kubernetes nodes.

Access configuration with:

terraform output -json configs | jq -r '."host.fqdn".conf'
