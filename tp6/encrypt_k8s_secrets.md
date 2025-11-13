Kubernetes Secrets Encryption (Minikube notes)

Kubernetes supports Envelope Encryption for secrets at rest. On Minikube, implement as follows (requires kube-apiserver flags):

1) Create an encryption config file (e.g., `/etc/kubernetes/encryption-config.yaml`):

```yaml
kind: EncryptionConfiguration
apiVersion: v1
resources:
  - resources:
    - secrets
    providers:
    - aescbc:
        keys:
        - name: key1
          secret: <BASE64_32_BYTES>
    - identity: {}
```

2) Start the API server with `--encryption-provider-config=/etc/kubernetes/encryption-config.yaml` and `--audit-log-path` set.

On Minikube you can modify the kube-apiserver manifest under `/var/lib/minikube/kubeadm.yaml` or use `minikube ssh` and edit static pod manifests in `/etc/kubernetes/manifests/`.

3) Restart the kube-apiserver (careful - this restarts control plane components).

Verification:
- Create a secret and inspect etcd data to ensure it is encrypted (requires access to etcd).

Notes:
- Keep the encryption key secure; rotating keys requires re-encrypting secrets.
- For production, integrate with KMS (HashiCorp Vault, AWS KMS, GCP KMS).
