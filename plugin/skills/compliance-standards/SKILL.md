---
name: compliance-standards
description: Use when wiring CI/CD compliance or the software supply chain — policy-as-code, SBOM, image signing & admission control. Org-opinionated standards; compliance is codified in the pipeline, not checked by hand.
---

# Compliance & Supply-Chain Standards (org)

Compliance is codified in the pipeline, not checked by hand.

## Policy-as-code
- Scan IaC **before deploy** with Open Policy Agent (via Conftest) against the **plan output** (`terraform show -json <plan>`).
- Real plan output is a **collection you iterate** — policies loop over `resource_changes`, never a hard-coded path. Use one paradigm (deny-based shown):

```rego
package terraform.s3.encryption
import rego.v1

deny contains msg if {
    some rc in input.resource_changes
    rc.type == "aws_s3_bucket"
    not rc.change.after.server_side_encryption_configuration
    msg := sprintf("S3 bucket %q must define server-side encryption.", [rc.address])
}
```

Fails the build with a clear message per offending resource.

## Software supply chain
- **SBOM:** every build emits a Software Bill of Materials (e.g. Syft) — direct + transitive deps + licenses. Cheap; enable everywhere.
- **Signing & admission:** production images signed in isolated CI with **Cosign (Sigstore)**; a Kubernetes admission controller verifies the signature before a container runs — unsigned or modified images rejected at admission.

## Supply-chain checklist
- [ ] IaC scanned (OPA/Conftest over plan output) before deploy.
- [ ] SBOM generated per build.
- [ ] Prod images signed; admission control enforcing signatures.
