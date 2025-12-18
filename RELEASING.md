# Release Process

This document describes how to create a new release of fmriprep-workbench.

## Overview

Releases are triggered manually using a flag file system. This prevents automatic releases on every push and gives you full control over when releases happen.

## Prerequisites

Before creating a release, ensure:

1. All changes for the release are merged to `main` branch
2. All tests are passing
3. Documentation is up to date
4. You have an `ANTHROPIC_API_KEY` secret configured in GitHub repository settings

## Creating a Release

### Method 1: Using the Helper Script (Easiest)

The quickest way to trigger a release is using the included helper script:

```bash
# For a patch release (0.2.0 -> 0.2.1)
./trigger-release.sh patch

# For a minor release (0.2.0 -> 0.3.0)
./trigger-release.sh minor

# For a major release (0.2.0 -> 1.0.0)
./trigger-release.sh major
```

The script will:
- ✅ Validate your input
- ✅ Show the current and next version
- ✅ Display commits since the last release
- ✅ Ask for confirmation
- ✅ Create and commit the `.release-ready` file
- ✅ Push to trigger the release workflow
- ✅ Provide a link to monitor the workflow

### Method 2: Using the Release Flag File Manually

1. **Create the release flag file** with the desired version bump type:

   ```bash
   # For a patch release (0.2.0 -> 0.2.1)
   echo "patch" > .release-ready

   # For a minor release (0.2.0 -> 0.3.0)
   echo "minor" > .release-ready

   # For a major release (0.2.0 -> 1.0.0)
   echo "major" > .release-ready
   ```

2. **Commit and push the flag file**:

   ```bash
   git add .release-ready
   git commit -m "chore: trigger release"
   git push origin main
   ```

3. **Monitor the release workflow**:
   - Go to the Actions tab in your GitHub repository
   - Watch the "Release" workflow execute
   - The AI-powered changelog will be generated automatically
   - The `.release-ready` file will be automatically removed after successful release

### Method 3: Manual Workflow Dispatch

Alternatively, you can trigger a release manually through GitHub's UI:

1. Go to **Actions** tab in your GitHub repository
2. Select the **Release** workflow from the left sidebar
3. Click **Run workflow** button
4. Select the version bump type (major, minor, or patch)
5. Click **Run workflow**

## Version Bump Types

- **patch**: Bug fixes and minor updates (0.2.0 → 0.2.1)
- **minor**: New features, backwards-compatible (0.2.0 → 0.3.0)
- **major**: Breaking changes (0.2.0 → 1.0.0)

## What Happens During Release

The release workflow automatically:

1. ✅ Reads the version bump type from `.release-ready` file
2. ✅ Calculates the new version number
3. ✅ Uses the **changelog-drafter AI agent** to generate human-readable release notes from commits
4. ✅ Updates `CHANGELOG.md` with the new version entry
5. ✅ Creates and pushes a git tag (e.g., `v0.2.1`)
6. ✅ Creates a GitHub release with AI-generated notes
7. ✅ Removes the `.release-ready` file to prevent re-triggering
8. ✅ Commits all changes back to the main branch

## AI-Powered Changelog Generation

The release workflow uses the `changelog-drafter` agent to automatically:

- Analyze all commits since the last release
- Translate technical commit messages into user-friendly language
- Categorize changes into sections:
  - 🚀 Features
  - 🐛 Bug Fixes
  - 📚 Documentation
  - 🔧 Maintenance
  - 💥 Breaking Changes
- Generate clear, descriptive release notes

## Troubleshooting

### Release workflow didn't trigger

- Ensure `.release-ready` file was committed and pushed to `main` branch
- Check the file contains exactly one of: `major`, `minor`, or `patch`
- Verify the workflow file exists at `.github/workflows/release.yml`

### AI changelog generation failed

The workflow has a fallback mechanism. If the AI agent fails, it will:
- Generate a simple commit-based changelog
- Still create the release successfully
- Log the error for investigation

### Release was created but flag file wasn't removed

- Check the workflow logs for errors in the "Remove release flag" step
- Manually remove the file with: `git rm .release-ready && git commit -m "chore: remove release flag" && git push`

## GitHub Secrets Required

Ensure these secrets are configured in your repository settings:

- `ANTHROPIC_API_KEY`: Your Anthropic API key for the changelog-drafter agent
- `GITHUB_TOKEN`: Automatically provided by GitHub Actions

## Best Practices

1. **Review changes before release**: Always review the commits that will be included
2. **Update docs first**: Ensure documentation reflects the changes being released
3. **Choose version bump carefully**: Follow semantic versioning principles
4. **Check workflow logs**: Monitor the release workflow to ensure everything succeeds
5. **Verify the release**: After creation, verify the release notes and download artifacts

## Examples

### Releasing a Bug Fix

```bash
# Make your bug fix commits
git commit -m "fix: correct subject counting logic"
git push origin main

# Trigger patch release
echo "patch" > .release-ready
git add .release-ready
git commit -m "chore: trigger v0.2.1 release"
git push origin main
```

### Releasing a New Feature

```bash
# Make your feature commits
git commit -m "feat: add skip-tar flag for step 2"
git push origin main

# Trigger minor release
echo "minor" > .release-ready
git add .release-ready
git commit -m "chore: trigger v0.3.0 release"
git push origin main
```

### Releasing Breaking Changes

```bash
# Make your breaking change commits
git commit -m "feat!: migrate to YAML configuration"
git push origin main

# Trigger major release
echo "major" > .release-ready
git add .release-ready
git commit -m "chore: trigger v1.0.0 release"
git push origin main
```

## Support

If you encounter issues with the release process, check:
- GitHub Actions workflow logs
- Repository issues for known problems
- Contact the maintainer for assistance
