# Project preferences

## Commit messages

The user explicitly asked to preserve the style of this repository's existing
commits. When asked for commit text:

- Write the commit message in English, even when the conversation is in Russian.
- Use one line: `type: concise description` (for example, `feat:`, `fix:`,
  `docs:`, `chore:`, or `perf:`).
- Start the description with a lowercase imperative verb such as `add`, `fix`,
  `hide`, or `preserve`. Do not end the line with a period.
- Describe the actual resulting change. Do not add a bullet list, a body,
  validation results, or a version summary unless the user requests them.
- Check recent meaningful commits with `git log` when uncertain. Ignore
  placeholder messages such as `chore:useless` as style examples.
- A request for commit text does not authorize creating a commit.

Example: `feat: simplify transaction filters and cards while preserving the original design`
