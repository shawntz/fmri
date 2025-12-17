# Documentation

This directory contains the Sphinx documentation for the SML fMRI Preprocessing Template.

## Building Documentation Locally

To build the documentation locally:

1. Install the required dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Build the HTML documentation:
   ```bash
   make html
   ```

3. Open the built documentation:
   ```bash
   open _build/html/index.html
   ```

## Documentation Structure

- `conf.py` - Sphinx configuration file
- `index.rst` - Main documentation page
- `installation.rst` - Installation guide
- `configuration.rst` - Configuration guide
- `usage.rst` - Usage guide
- `workflows.rst` - Detailed workflow documentation
- `contributing.rst` - Contributing guidelines
- `changelog.rst` - Changelog page

## ReadTheDocs

Documentation is automatically built and published on ReadTheDocs when changes are pushed to the repository.

Visit: https://fmriprep-workbench.readthedocs.io/

## Adding New Pages

1. Create a new `.rst` file in this directory
2. Add the page to the `toctree` in `index.rst`
3. Build and test locally before committing

## Markdown Support

This documentation supports both reStructuredText (`.rst`) and Markdown (`.md`) files via the MyST parser.
