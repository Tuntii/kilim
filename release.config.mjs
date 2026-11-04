// semantic-release: run by the release job in .github/workflows/ci.yml on master.
// Commits follow Conventional Commits; fix and perf make a patch release, feat a
// minor one, other types none.

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
        // Until 1.0 a breaking change is a minor release, not 1.0.0.
        releaseRules: [{ breaking: true, release: "minor" }],
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
