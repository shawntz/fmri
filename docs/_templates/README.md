# Custom Templates Directory

This directory contains custom Sphinx templates that override or extend the default theme templates.

## Files

- `layout.html`: Extends the base theme layout to add the Seline tracking script to all documentation pages.

## Purpose

These templates are used during the Sphinx documentation build process to inject custom HTML, scripts, or other modifications across all generated documentation pages.

## Analytics and Privacy

The `layout.html` template adds the Seline analytics tracking script to every generated documentation page. This analytics tracking helps us understand documentation usage patterns and improve content quality.

**What is tracked**: Page views, navigation patterns, technical information (browser, OS), and anonymized usage metrics.

**What is NOT tracked**: Personal identifiable information, research data, login credentials, or full IP addresses.

For complete details about data collection, usage, and how to opt out, please see our **[Privacy Policy](../privacy.rst)** in the documentation.
