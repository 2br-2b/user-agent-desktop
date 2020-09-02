const path = require("path");
const fs = require("fs").promises;

const execa = require("execa");

function getPathToVersion() {
  return path.join("mozilla-release", "browser", "config", "version.txt");
}

function getPathToVersionDisplay() {
  return path.join(
    "mozilla-release",
    "browser",
    "config",
    "version_display.txt"
  );
}

async function getVersionDisplay(version) {
  const { stdout: commitHash } = await execa("git", [
    "rev-parse",
    "--short",
    "HEAD",
  ]);
  return `${version} (${commitHash})`;
}

module.exports = {
  name: "Setup app version",
  paths: ["browser/config/version.txt", "browser/config/version_display.txt"],
  skip: async ({ app: version }) =>
    (await fs.readFile(getPathToVersion(), "utf-8")) === version &&
    (await fs.readFile(getPathToVersionDisplay(), "utf-8")) ===
      (await getVersionDisplay()),
  apply: async ({ app: version }) => {
    await fs.writeFile(getPathToVersion(), version, "utf-8");
    await fs.writeFile(
      getPathToVersionDisplay(),
      await getVersionDisplay(),
      "utf-8"
    );
  },
};
