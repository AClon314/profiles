podman image list --all | grep none | awk '{print $3}' | xargs -I % podman image rm %

