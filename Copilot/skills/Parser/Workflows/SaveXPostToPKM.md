# Save X Post to PKM Workflow

## Purpose

Save an X/Twitter post or X Article into Robley's PKM without rediscovering tools.

Use this workflow for requests like:

- "save this X post"
- "fetch this x post and put it in PKM"
- "save this X Article to careers"
- "archive this tweet"

## Standard tool

Use this script as the standard capture tool:

```bash
cd /Users/robley/projects/youtube-transcript-archiver &&
./save_x_content.sh '<x-url>' extract_wisdom
```

Why this is the standard:

- It successfully handles normal X/Twitter status URLs.
- It detects X Article redirects from `yt-dlp` and fetches full article text through the X API path.
- It writes two local artifacts under `~/dev/anthropic_pro_4/`: a `_content.txt` source capture and an `_extract_wisdom.md` synthesis.
- It imports the generated files to DEVONthink when the local DEVONthink import script is available.

Do not start with public oEmbed, raw X HTML, web search, Nitter, or ad hoc GraphQL attempts. Those are fallback/debug paths only after this script fails.

## Xurl comparison

The previous "xurl" capture reference was a capture note naming the same successful pattern: X API/Hermes capture producing `_content.txt` and `_extract_wisdom.md` files. No separate reusable `xurl` command was found in PATH. Standardize on `save_x_content.sh` and treat "xurl" as historical shorthand, not the primary tool to search for.

## Workflow

1. Send the Parser voice notification.
2. Run the standard tool:

   ```bash
   cd /Users/robley/projects/youtube-transcript-archiver &&
   ./save_x_content.sh '<x-url>' extract_wisdom
   ```

3. Read the generated files printed by the script:
   - `Content: ..._content.txt`
   - `Pattern: ..._extract_wisdom.md`
4. If the user asked for a PKM knowledge space, write a clean markdown note into that PKM folder.
5. Verify the PKM file exists and is non-empty.

## PKM destinations

Known destination:

- Careers knowledge space: `/Users/robley/Library/CloudStorage/OneDrive-GreatBayLabs/PKM/70_Career/Career & Work/`

If the user names a destination that is ambiguous and no existing path is obvious from PKM search, ask before writing.

## PKM note shape

Create a single markdown note with:

- Title
- Source URL and article URL, when available
- Author/handle, when available
- Published and captured timestamps
- Topic tags or one-line topic
- Short summary
- "Why this matters" or destination-specific relevance
- Key ideas
- Source text

Prefer a readable PKM note over copying only the raw script artifact.

## Expected script behavior

For X Articles, this warning is expected and is not a failure:

```text
yt-dlp error: ... Unsupported URL: https://x.com/i/article/...
Detected X Article post. Fetching full article via Twitter API...
```

Continue if the script later prints `Processing complete!`.

## Failure handling

- If the script reports missing Twitter auth cookies, stop and report that X auth cookies are needed at `~/.config/yt-dlp/twitter_cookies.txt` or via `TWITTER_COOKIES_FILE`.
- If Fabric is missing, the raw content may still be usable; save the content artifact and note that synthesis was skipped.
- If DEVONthink import fails, continue with PKM file creation from the generated local artifacts.
- Do not claim the post is saved until the target PKM markdown file exists.
