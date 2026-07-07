# Testing generic Slinky images

The [Dockerfile](Dockerfile) is based on UBI9 and uses a similar process for building Slurm from source but then installs all of the Slurm RPMs to create a mega image.

In [config/](config) the kustomize builds out ConfigMaps, the files/ is pulled directly from slinkyproject/containers (schedmd/slurm/26.05/rockylinux9/files)

The [values.yaml](values.yaml) mounts the ConfigMaps created by kustomize in the NodeSet using the generic mega image created by the Dockerfile.

Going forward, these ConfigMaps could be managed by either Helm or the operator itself.
