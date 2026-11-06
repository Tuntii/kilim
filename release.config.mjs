// semantic-release: run by the release job in .github/workflows/ci.yml on master.
// Commits follow Conventional Commits. One release a month, run by hand (Run
// workflow on CI, branch master): feat and breaking changes make the minor release
// (pre-1.0), fix and perf alone a patch; other types make none.

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
        // Matching rules win over the preset's defaults (feat: minor); breaking is held to minor before 1.0.
        releaseRules: [
          { breaking: true, release: "minor" },
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
