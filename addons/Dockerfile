FROM localhost/slurm:systemd

RUN dnf -y groupinstall "Development Tools"
RUN dnf -y install openssl-devel bzip2-devel jq


# Ref: https://slurm.schedmd.com/quickstart_admin.html#rpmbuild
RUN <<EOR
git clone --depth=2 https://github.com/spack/spack.git /opt/spack
. /opt/spack/share/spack/setup-env.sh

cat <<EOF > /tmp/slurm.conf
ClusterName=dummy_cluster
SlurmctldHost=localhost
SelectType=select/cons_res
SlurmctldPidFile=/tmp/slurmctld.pid
EOF
export SLURM_CONF=/tmp/slurm.conf

spack external find slurm
rm /tmp/slurm.yaml

spack compiler find
spack external find

spack install openmpi fabrics=ucx
EOR



