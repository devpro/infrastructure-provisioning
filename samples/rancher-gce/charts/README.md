# Helm Charts

## Catalog

* [Cluster API (CAP) templates](capi-templates/README.md)

## Developer's guide

From within a chart directory:

```bash
# lints a chart
helm lint

# generates the manifest file from a chart (for review/comparison)
helm template <releasename> . -f values.yaml -f values_mine.yaml --namespace demo > temp.yaml

# installs a chart from local source
helm upgrade --install <releasename> . -f values.yaml \
  # --debug > output.yaml \
  --create-namespace --namespace demo
```
