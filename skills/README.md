# Agent skills

Use these skills individually. Copy the complete skill folder to a location your client supports, or use that client's skill installer. Keep these styles out of always-on repository instructions so you can request them when they suit the task.

| Skill | When to use it |
| --- | --- |
| [AI Repo Onboard](ai-repo-onboard) | Inspect and improve a repository's AI guidance using evidence from its files. |
| [Caveman](caveman) | Ask for terse engineering replies. Commands, paths, numbers, and error text retain their meaning. Use normal mode to turn it off. |
| [Simple English](simple-english) | Write readable documentation, setup steps, release notes, and explanations for a broad audience. |

Caveman targets the length of user-facing replies. Simple English targets clarity and can use more words when a definition helps. Token use depends on the model, task, and output. Neither style changes the model's context limit.

## Upstream versions

- **Caveman** includes the core Markdown skill from [Julius Brussee's pinned source](https://github.com/JuliusBrussee/caveman/tree/47c61be2d10a354f0c5cbe2b90959d24c06b16c6/skills/caveman), with its [Apache-2.0 license](caveman/LICENSE), [MIT notice](caveman/LICENSE-MIT), and [upstream attribution](caveman/NOTICE). Alternate modes, hooks, and proxy features require the upstream package.
- **Simple English** includes the full Markdown skill and reference folder from [AminBlg's pinned source](https://github.com/AminBlg/SimpleEnglish/tree/300432a9e4c473229a7049ab61b8ca2522d9214c/skills/simple-english), with its [MIT license](simple-english/LICENSE). Plugin-specific hooks and output styles are documented upstream.
