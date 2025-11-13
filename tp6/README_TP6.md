TP6: Kubernetes Security Hardening (Minikube)

Overview
--------
This TP6 package provides Kubernetes security manifests and guidance for Minikube: RBAC limits, NetworkPolicies, OPA Gatekeeper ConstraintTemplates/Constraints, Pod Security admission guidance, secrets encryption at rest, and verification scripts.

Included files
- `rbac_restrict.yaml` - example Roles and RoleBindings to limit namespace access
- `networkpolicy_default_deny.yaml` - default deny NetworkPolicy with allowed app ingress examples
- `gatekeeper_constraint_template_image_vuln.yaml` - OPA Gatekeeper ConstraintTemplate to block certain images or unscanned images
- `gatekeeper_constraint_image_vuln.yaml` - example Constraint using the template
- `podsecurity_restrictive.yaml` - PodSecurity admission labels to enforce `restricted` for namespaces
- `encrypt_k8s_secrets.md` - steps to enable envelope encryption for secrets in Kubernetes (minikube)
- `verify_tp6.sh` - script to verify that policies are in effect

Notes
- Gatekeeper requires installation in cluster: `kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml` (or use the release manifest).
- Minikube's default storage must be adjusted to enable secrets encryption; steps provided in `encrypt_k8s_secrets.md`.
- NetworkPolicy requires a CNI that supports it (e.g., Calico). Minikube can use calico addon or install calico manually.
