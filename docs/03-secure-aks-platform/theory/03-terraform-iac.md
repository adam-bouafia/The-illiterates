# 3. Infrastructure as Code with Terraform

## The problem with clicking buttons

You can build an entire AKS cluster, a VNet, a Key Vault, and everything
else in this project by clicking through the Azure Portal. It works, once.
Then:

- You need to build the exact same thing again (a second environment, a
  disaster-recovery rebuild, a colleague's test environment) and you're
  trying to remember which 40 checkboxes you ticked last time.
- Something changes - someone clicks a setting in the Portal "just to try
  something" - and now nobody can say with confidence what the
  infrastructure actually looks like versus what it's supposed to look
  like. This is called **drift**.
- There's no code review for a sequence of mouse clicks. There's no
  history of *why* a setting was chosen, beyond someone's memory.
- Tearing it all down cleanly, with nothing left over racking up cost, is
  just as manual and just as error-prone as building it.

**Infrastructure as Code (IaC)** fixes all of this by describing
infrastructure in a file, checked into version control, the same way
application code is. The file is the single source of truth. Building the
infrastructure means running a tool against that file. Rebuilding it
identically means running the same tool against the same file again.
Reviewing a change means reviewing a diff, same as any other pull request.

## What Terraform actually is

**Terraform** is the tool this project uses. It's **declarative**: you
write what you want the end state to look like, not the step-by-step
commands to get there. You write "a resource group named `rg-ledger-lab`
in `germanywestcentral`", not "run `az group create ...`". Terraform
figures out the actual sequence of API calls needed to make reality match
what you described - and, just as importantly, figures out what to change
when you *update* that description, touching only what actually needs to
change.

Terraform talks to a cloud through a **provider** - a plugin that knows
how to translate Terraform's generic concepts into a specific cloud's API
calls. This project uses the `azurerm` provider (Azure Resource Manager).
The exact same approach, same `plan`/`apply` workflow, works for AWS,
Google Cloud, or dozens of other providers - only the provider and the
resource names change.

## The basic unit: a resource block

Here's an actual, simplified resource from this project
(`infra/network.tf`):

```hcl
resource "azurerm_resource_group" "main" {
  name     = "rg-ledger-lab"
  location = "germanywestcentral"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-ledger-lab"
  address_space       = ["10.10.0.0/16"]
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}
```

Breaking down `resource "azurerm_virtual_network" "main" { ... }`:

- `azurerm_virtual_network` - the *type* of resource (this exact name is
  defined by the `azurerm` provider; every resource type it supports has
  one).
- `"main"` - a *local name*, used only within this Terraform configuration
  to refer back to this specific resource. It never appears in Azure
  itself.
- `resource_group_name = azurerm_resource_group.main.name` - this is the
  important part: **a reference to another resource's attribute.**
  Terraform reads this, understands that the VNet depends on the resource
  group, and automatically creates the resource group *first*. You never
  write "create X, then create Y" - the dependency graph is inferred
  entirely from these references.

## The workflow: init, plan, apply, destroy

Four commands make up essentially the whole Terraform experience:

```bash
terraform init      # downloads the provider plugin, sets up local state
terraform plan       # shows exactly what WOULD change, without changing anything
terraform apply       # actually makes those changes
terraform destroy      # tears everything back down
```

`terraform plan` is the single most important habit here. It is a dry
run: Terraform compares the `.tf` files against what it currently believes
exists (more on that below) and prints a diff - lines prefixed with `+`
for things that will be created, `-` for things that will be destroyed,
`~` for things that will be changed in place. Reading that diff *before*
running `apply` is how you catch "wait, that's not supposed to delete
anything" before it actually happens.

A real, trimmed example of what that output looks like, from this
project:

```
Terraform will perform the following actions:

  # azurerm_resource_group.main will be created
  + resource "azurerm_resource_group" "main" {
      + id       = (known after apply)
      + location = "germanywestcentral"
      + name     = "rg-ledger-lab"
    }

Plan: 5 to add, 0 to change, 0 to destroy.
```

`terraform destroy` runs the same logic in reverse - and it's worth saying
plainly: a cloud resource that's running (a Kubernetes cluster, a VM) is
billed by the hour, whether you're using it or not. `terraform destroy`,
run at the end of every work session, is the single most important cost
control in this entire project. Leave a cluster running overnight by
accident and you've paid for a night of doing nothing.

## State: Terraform's memory

Terraform needs to remember what it has already created, so that the next
`plan` can compare "what the `.tf` files say" against "what I last knew
to exist" rather than against "whatever Azure says exists right now"
(which would require scanning the entire subscription every time, and
wouldn't distinguish resources Terraform manages from ones it doesn't).
That memory is the **state file** (`terraform.tfstate`), a JSON file
Terraform writes after every `apply`.

```bash
terraform state list
```

prints every resource Terraform currently believes it's responsible for.
In this project, by the time every layer was built, that list had grown
to:

```
data.azurerm_client_config.current
azurerm_container_registry.main
azurerm_federated_identity_credential.ledger_api
azurerm_key_vault.main
azurerm_key_vault_secret.api_key
azurerm_kubernetes_cluster.main
azurerm_log_analytics_workspace.main
azurerm_resource_group.main
azurerm_role_assignment.kubelet_acr_pull
azurerm_role_assignment.kv_terraform_writer
azurerm_role_assignment.ledger_api_kv_reader
azurerm_subnet.aks
azurerm_user_assigned_identity.ledger_api
azurerm_virtual_network.main
random_password.api_key
random_string.kv_suffix
```

Sixteen resources - a resource group, a VNet, a subnet, an AKS cluster, a
container registry, a Key Vault with a secret in it, a Log Analytics
workspace, a user-assigned identity with a federated credential, three
role assignments, and two small helper resources (a random password and a
random string, both generated by Terraform itself rather than typed by a
human - more on exactly why in
[Identity and Secrets](04-identity-and-secrets.md)). Every single one of
those traces back to a resource block in a `.tf` file, and every single
one can be destroyed cleanly by the same tool that created it.

## A real, honest lesson: a brand-new cloud subscription starts almost empty

Something worth knowing before it surprises you: a freshly created Azure
subscription doesn't come with every Azure service ready to use. Each
service - virtual machines, AKS, container registries, Key Vault, Log
Analytics, even basic monitoring - is its own "resource provider", and a
subscription has to explicitly **register** a provider before it can
create the first resource of that type. This isn't something you'd know to
do proactively; it only shows up as an error, something like:

```
MissingSubscriptionRegistration: The subscription is not registered
to use namespace 'Microsoft.ContainerService'.
```

The fix is simple once you know to look for it:

```bash
az provider register --namespace Microsoft.ContainerService
az provider show -n Microsoft.ContainerService --query registrationState
```

...wait a minute or two for it to say `Registered`, and retry. On a fresh
subscription, it's worth registering the handful of providers you know
you'll need (`Microsoft.Compute`, `Microsoft.ContainerService`,
`Microsoft.Network`, `Microsoft.ContainerRegistry`, `Microsoft.KeyVault`,
`Microsoft.OperationalInsights`, `Microsoft.OperationsManagement`,
`Microsoft.ManagedIdentity`, `microsoft.insights`) up front, rather than
discovering them one at a time, mid-`apply`, which is exactly how it
happened in this project the first time around.

## Another real lesson: not every region, and not every VM size, is available to you

Some subscriptions (student, trial, or heavily cost-controlled ones) have
Azure Policy restrictions on *which regions* you're allowed to deploy
into, and separately, a **quota** - a hard cap on how many virtual CPUs
you're allowed to run at once, broken down by VM "family" (a group of
similar VM sizes). Both show up only when you try to actually create the
resource:

```
RequestDisallowedByPolicy: Resource 'rg-ledger-lab' was disallowed by policy.
```

or

```
InsufficientVCPUQuota: Operation could not be completed as it results in
exceeding approved Total Regional vCPU quota.
```

Two commands check both of these *before* you waste time on a failed
`apply`:

```bash
az policy assignment list                      # any region restrictions?
az vm list-usage --location <region> -o table    # quota per VM family, and the
                                                  # regional total, in that region
```

And for AKS specifically, there's a second, separate allow-list beyond
general compute quota - not every VM size that Azure sells is accepted for
an AKS node pool at all (Burstable "B-series" VMs, for example, are
excluded everywhere, on every subscription, because their throttled CPU
performance is a poor fit for Kubernetes workloads):

```bash
az aks list-vm-skus --location <region>
```

## What's next

With infrastructure that can be built and destroyed reliably and
reviewably, the next question is the one this whole project centers
around: how does the application running on that infrastructure get its
secret, without that secret ever being written down anywhere a leak could
expose it? That's [Identity and Secrets: Workload Identity](04-identity-and-secrets.md).
