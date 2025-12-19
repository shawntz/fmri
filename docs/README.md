# Documentation

This directory contains the MkDocs documentation for the fMRIPrep Workbench.

## Building Documentation Locally

To build the documentation locally:

1. Install the required dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Serve the documentation locally (with live reload):
   ```bash
   cd ..  # Navigate to repository root
   mkdocs serve
   ```

3. Open your browser to view the documentation:
   ```
   http://127.0.0.1:8000
   ```

## Building Static HTML

To build static HTML files:

```bash
cd ..  # Navigate to repository root
mkdocs build
```

The built documentation will be in the `site/` directory.

## Building with PDF

To build documentation with PDF generation:

```bash
cd ..  # Navigate to repository root
ENABLE_PDF_EXPORT=1 mkdocs build
```

The PDF will be available at `site/pdf/fmriprep-workbench-documentation.pdf`.

## Documentation Structure

- `index.md` - Main documentation page
- `installation.md` - Installation guide
- `configuration.md` - Configuration guide
- `usage.md` - Usage guide
- `workflows.md` - Detailed workflow documentation
- `contributing.md` - Contributing guidelines
- `changelog.md` - Changelog page

## GitHub Pages

Documentation is automatically built and published on GitHub Pages when changes are pushed to the main branch.

Visit: https://shawntz.github.io/fmriprep-workbench/

## Adding New Pages

1. Create a new `.md` file in this directory
2. Add the page to the `nav` section in `../mkdocs.yml`
3. Test locally with `mkdocs serve` before committing

## Markdown Format

This documentation uses Markdown format with Material for MkDocs extensions, including:

- Fenced code blocks with syntax highlighting
- Admonitions (`!!! note`, `!!! warning`, etc.)
- Tables
- Task lists
- Definition lists

For more information on supported Markdown syntax, see the [Material for MkDocs documentation](https://squidfunk.github.io/mkdocs-material/reference/).
