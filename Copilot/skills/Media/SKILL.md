---
name: Media
description: Visual and video content creation — illustrations, diagrams, mermaid flowcharts, infographics, header images, PAI pack icons, thumbnails, comics, and programmatic video via Remotion. USE WHEN art, header images, visualizations, mermaid, diagrams, flowcharts, infographics, pack icons, video, animation, motion graphics, Remotion, video rendering, YouTube thumbnails, comics, comparisons, frameworks, maps, timelines, taxonomies, stats, aphorisms, recipe cards, annotated screenshots, D3 dashboards, embossed logo wallpaper, remove background, essay illustration, technical diagrams, content to animation, generate image, Midjourney.
---

# Media

Unified skill for visual and video content creation.

## 🔀 Copilot Spike Status (2026-04-20)

**Only the Mermaid diagram workflow is verified working in the Copilot port.**
Everything else in `Art/` depends on one of:
- **Midjourney** via the `GenerateMidjourneyImage.ts` tool (needs API key)
- **OpenAI image gen** via the `Generate.ts` / `ComposeThumbnail.ts` tools
- **Remotion** (React video renderer, not ported)

If a user asks for illustrations, thumbnails, comics, essay art, D3
dashboards, or anything else image-generation-based, explain the limitation
and offer to (a) generate Mermaid equivalents where possible, or (b) fall
back to direct `web_fetch` / prompt-based external tools. The `Art` skill
tree is present for future re-enabling but should be treated as advisory,
not executable, outside of Mermaid.

## Workflow Routing

| Request Pattern | Route To |
|---|---|
| Mermaid, flowchart, technical diagram (code-renderable) | `Art/Workflows/Mermaid.md` |
| Visualizations, pack icons, infographics, header images, thumbnails, comics, essay art | **API-gated** — see Copilot Spike Status above |
| Video, animation, motion graphics, Remotion, React video | **Not ported** — `Remotion/` requires a full React video pipeline |
