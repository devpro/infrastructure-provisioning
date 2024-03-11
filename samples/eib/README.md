# Edge Image Builder (EIB)

## EIB container image

At this time, the image is not available in a registry, it needs to be created locally from the sources:

```bash
cd $SOME_FOLDER
git clone https://github.com/suse-edge/edge-image-builder.git
cd edge-image-builder
docker build -t eib:dev .
```

## ISO creation

Download SLE Micro iso from [suse.com/download/sle-micro](https://www.suse.com/download/sle-micro/) and copy it to `base-images` directory.

Create/update configuration file. Passwords can be generated with `openssl passwd -6 somepassword`.

Use EIB image to create an iso file for a given configuration file:

```bash
docker run --rm -it \
-v $(pwd):/eib eib:dev build \
--config-file eib-minimalist.yaml \
--config-dir /eib \
--build-dir /eib/_build
```

Use the iso file to create a new VM (on Hyper-V for example), boot on the CDROM, then edit the configuration to boot on the hard drive.

Login with root/root (or the username/password you configured).
