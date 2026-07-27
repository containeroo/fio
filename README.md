# fio

An Alpine Linux based image for running `fio` storage benchmarks.

The image includes:

- pinned Alpine packages for `fio`, `jq`, `nfs-utils`, `procps-ng`, and
  `util-linux`
- `catatonit` as PID 1 for signal forwarding and zombie reaping
- Bash for the default command and benchmark scripts

The Alpine image tag and every explicitly installed APK are tracked by
Renovate.

## Run

```bash
docker run --rm -it ghcr.io/containeroo/fio:latest
```

The default command sleeps indefinitely. Override it to run `fio` directly:

```bash
docker run --rm ghcr.io/containeroo/fio:latest \
  fio --name=smoke --filename=/tmp/fio.test --size=64M --rw=write
```

## Kubernetes example

The manifests under [`examples`](examples) show how to attach a test PVC. The
scripts under [`examples/scripts`](examples/scripts) contain limited and full benchmark suites.
These tests write data and can create significant storage load; use only a
dedicated test volume.
