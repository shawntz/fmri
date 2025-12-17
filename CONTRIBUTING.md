# Contributing to the SML fMRI Preprocessing Template

## Welcome!

Thank you for considering contributing to our lab's fMRI preprocessing pipeline. We created this template to be community-driven, as we believe the best preprocessing practices emerge from collective expertise and rigorous discussion.

## How Can I Contribute?

### Scientific Contributions
- [ ] Identify potential issues in preprocessing steps
- [ ] Suggest improvements based on recent literature
- [ ] Share knowledge about best practices
- [ ] Question assumptions in our implementation
- [ ] Propose new validation checks

### Technical Contributions
- [ ] Bug fixes
- [ ] Code optimization
- [ ] Documentation improvements
- [ ] Example additions
- [ ] Test cases

## Contribution Process

1. **Start with an Issue**
   - Search existing issues first
   - Create a new issue to discuss your proposed changes
   - Wait for maintainer feedback before significant work

2. **Fork & Create Branch**
   - Fork the repository
   - Create a branch for your changes
   - Use clear branch names (e.g., `fix-fieldmap-volumes`, `improve-distortion-correction`)

3. **Make Changes**
   - Follow existing code style
   - Add comments explaining preprocessing decisions
   - Update documentation as needed
   - Add tests if applicable
   - Use conventional commit messages (see below)

4. **Submit Pull Request**
   - Provide clear description of changes
   - Link related issues
   - Include scientific rationale for preprocessing changes
   - Add before/after examples if possible

## Pull Request Guidelines

1. **Scientific Validity**
   - Explain the scientific rationale for changes
   - Cite relevant literature
   - Describe impact on preprocessing quality

2. **Code Quality**
   - Follow Python (PEP 8) and Shell script conventions
   - Include comments explaining preprocessing decisions
   - Maintain existing error checking patterns
   - Add appropriate logging

3. **Documentation**
   - Update README (only if needed)
   - Add inline documentation
   - Update parameter descriptions
   - Include clear and generalizable examples

4. **Testing**
   - Add validation checks
   - Test with different data types
   - Verify BIDS compliance
   - Check edge cases

## Commit Message Guidelines

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automated changelog generation and semantic versioning.

### Format

```
<type>(<scope>): <subject>
```

### Types

- `feat`: New feature (MINOR version bump)
- `fix`: Bug fix (PATCH version bump)
- `docs`: Documentation only changes
- `style`: Formatting changes (no code change)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `build`: Build system changes
- `ci`: CI configuration changes
- `chore`: Other changes (no src/test changes)

### Breaking Changes

Add `!` after type or `BREAKING CHANGE:` in footer for MAJOR version bump:

```
feat!: remove deprecated API

BREAKING CHANGE: The old API endpoint has been removed.
```

### Examples

**Feature:**
```
feat(preprocessing): add multi-echo support
```

**Bug Fix:**
```
fix(fieldmap): correct IntendedFor mapping

Fixes #123
```

**Documentation:**
```
docs: update configuration guide
```

## Release Process

Releases are automated via GitHub Actions:
1. Commits are analyzed on push to main
2. Version is determined from commit messages
3. Changelog is generated automatically
4. GitHub release is created

See [Semantic Versioning](https://semver.org/) for version numbering details.

## Questions?

Feel free to:
- Open an issue for discussion
- Ask for clarification on existing issues
- Request more detailed contribution guidelines

We appreciate your help in maintaining high-quality preprocessing standards!

cheers,
shawn
