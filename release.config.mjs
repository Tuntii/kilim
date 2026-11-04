// semantic-release: run by the release job in .github/workflows/ci.yml on master.
// Commits follow Conventional Commits. For now fix, perf and feat all make a patch
// release, breaking changes included (they are listed in the notes); other types
// make none. A new minor version is a deliberate step: tag vX.Y.0 on master by
// hand, and semantic-release continues from that tag.

// `#` starts an issue reference only before a digit, so iyi method names in commit
// bodies (`Widget#layout`) are not read as issues. A RegExp, because the parser
// escapes string prefixes.
const parserOpts = { issuePrefixes: [/#(?=\d)/] };

export default {
  branches: ["master"],
  tagFormat: "v${version}",
  plugins: [
    [
      "@semantic-release/commit-analyzer",
      {
        preset: "conventionalcommits",
        parserOpts,
        // Matching rules win over the preset's defaults (feat: minor, breaking: major).
        releaseRules: [
          { breaking: true, release: "patch" },
          { type: "feat", release: "patch" },
        ],
      },
    ],
    [
      "@semantic-release/release-notes-generator",
      {
        preset: "conventionalcommits",
        parserOpts,
        presetConfig: {
          types: [
            { type: "feat", section: "Features" },
            { type: "fix", section: "Bug Fixes" },
            { type: "perf", section: "Performance" },
            { type: "docs", hidden: true },
            { type: "bench", hidden: true },
            { type: "ci", hidden: true },
            { type: "chore", hidden: true },
            { type: "refactor", hidden: true },
            { type: "test", hidden: true },
          ],
        },
      },
    ],
    "@semantic-release/github",
  ],
};
