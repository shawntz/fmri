Contributing
============

.. include:: ../CONTRIBUTING.md
   :parser: myst_parser.sphinx_

Commit Message Guidelines
--------------------------

This project uses `Conventional Commits <https://www.conventionalcommits.org/>`_
for automated changelog generation and semantic versioning.

Commit Message Format
~~~~~~~~~~~~~~~~~~~~~

Each commit message should follow this structure:

.. code-block:: text

   <type>(<scope>): <subject>

   <body>

   <footer>

Types
~~~~~

- ``feat``: A new feature (triggers MINOR version bump)
- ``fix``: A bug fix (triggers PATCH version bump)
- ``docs``: Documentation only changes
- ``style``: Changes that don't affect code meaning (formatting, etc.)
- ``refactor``: Code change that neither fixes a bug nor adds a feature
- ``perf``: Performance improvements
- ``test``: Adding or updating tests
- ``build``: Changes to build system or dependencies
- ``ci``: Changes to CI configuration files and scripts
- ``chore``: Other changes that don't modify src or test files

Breaking Changes
~~~~~~~~~~~~~~~~

Add ``!`` after the type or ``BREAKING CHANGE:`` in the footer to trigger
a MAJOR version bump:

.. code-block:: text

   feat!: remove deprecated API endpoint

   BREAKING CHANGE: The /api/v1/old endpoint has been removed.
   Use /api/v2/new instead.

Examples
~~~~~~~~

**Feature Addition:**

.. code-block:: text

   feat(preprocessing): add support for multi-echo fMRI

   Implement multi-echo fMRI preprocessing workflow with optimal
   combination of echoes using tedana.

**Bug Fix:**

.. code-block:: text

   fix(fieldmap): correct IntendedFor field mapping

   Fix issue where fieldmap IntendedFor fields were not properly
   updated for runs with non-sequential numbering.

   Fixes #123

**Documentation:**

.. code-block:: text

   docs: update configuration guide with new parameters

   Add documentation for FMRIPREP_OUTPUT_SPACES and clarify
   fieldmap mapping syntax.

**Breaking Change:**

.. code-block:: text

   feat!: update to fMRIPrep 24.0.0

   BREAKING CHANGE: Update to fMRIPrep 24.0.0 which requires
   different output space syntax. Update settings.template.sh
   accordingly.

Scope
~~~~~

Optional, but recommended. Common scopes include:

- ``preprocessing``
- ``fieldmap``
- ``config``
- ``workflow``
- ``docs``
- ``ci``

Release Process
---------------

Releases are automated using GitHub Actions. When commits are pushed to the
main branch:

1. The workflow analyzes commit messages
2. Determines the appropriate version bump (MAJOR, MINOR, or PATCH)
3. Generates a changelog from commits
4. Creates a Git tag
5. Publishes a GitHub release

Manual Release
~~~~~~~~~~~~~~

To manually trigger a release with a specific version bump:

1. Go to Actions → Release workflow
2. Click "Run workflow"
3. Select the version bump type (major, minor, or patch)
4. Click "Run workflow"

Version Numbering
~~~~~~~~~~~~~~~~~

This project follows `Semantic Versioning <https://semver.org/>`_:

- **MAJOR** version: Incompatible API changes or breaking changes
- **MINOR** version: New features in a backwards compatible manner
- **PATCH** version: Backwards compatible bug fixes

Development Workflow
--------------------

1. Fork and Branch
~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   git clone https://github.com/your-username/fmri.git
   cd fmri
   git checkout -b feat/your-feature-name

2. Make Changes
~~~~~~~~~~~~~~~

Follow the contribution guidelines in CONTRIBUTING.md:

- Write clear, documented code
- Add tests if applicable
- Update documentation
- Use conventional commit messages

3. Test Locally
~~~~~~~~~~~~~~~

Test your changes before submitting:

.. code-block:: bash

   # Test with a single subject
   ./launch

   # Verify BIDS compliance
   bids-validator /path/to/test/data

4. Commit Changes
~~~~~~~~~~~~~~~~~

Use conventional commit format:

.. code-block:: bash

   git add .
   git commit -m "feat(preprocessing): add new validation check"

5. Push and Create PR
~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   git push origin feat/your-feature-name

Then create a Pull Request on GitHub with:

- Clear description of changes
- Link to related issues
- Scientific rationale (if applicable)
- Before/after examples (if applicable)

Code Review Process
-------------------

1. Automated checks run on your PR
2. Maintainers review your changes
3. Address any feedback
4. Once approved, your PR will be merged
5. Release workflow will automatically handle versioning

Changelog Maintenance
---------------------

The CHANGELOG.md file is automatically updated by the release workflow.
You don't need to manually edit it when contributing.

Documentation
-------------

Documentation is built automatically on ReadTheDocs when changes are pushed.

To build documentation locally:

.. code-block:: bash

   cd docs
   pip install sphinx sphinx-rtd-theme myst-parser
   make html
   open _build/html/index.html

Questions?
----------

- Open an issue for discussion
- Ask for clarification on existing issues
- Contact maintainers through GitHub

We appreciate your contributions to maintaining high-quality preprocessing standards!
