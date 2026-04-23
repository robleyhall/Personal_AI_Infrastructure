> **Ported from upstream [danielmiessler/Personal_AI_Infrastructure](https://github.com/danielmiessler/Personal_AI_Infrastructure) v4.0.3.** Mechanical port.

---

# User Workflows

Your custom workflow definitions. These extend PAI's built-in skill workflows with your own automation sequences.

## Creating a Workflow

Create markdown files that define multi-step processes:

```markdown
# My Custom Workflow

## Trigger
"run my weekly review"

## Steps
1. Gather data from [source]
2. Analyze using [skill]
3. Output to [destination]
```

PAI's routing system can discover and execute workflows placed here.
