> **Ported from upstream [danielmiessler/Personal_AI_Infrastructure](https://github.com/danielmiessler/Personal_AI_Infrastructure) v4.0.3.** Mechanical port.

---

# Data Pipelines

YAML-based data processing pipeline configurations. Pipelines define how content flows through extraction, transformation, and loading steps.

## Format

```yaml
# example.pipeline.yaml
name: content-ingest
steps:
  - action: extract
    source: url
  - action: transform
    template: summarize
  - action: load
    destination: database
```

Place `.pipeline.yaml` files in this directory.
