---
name: Security Check
description: Verify repository security and check for secrets using gitleaks
---

# Security Check Skill

This skill provides instructions for ensuring the repository is secure and free of secrets.

## Gitleaks Detection

To verify that the repository contains no secrets, run the following command in the repository root:

```bash
gitleaks detect -v
```

### If leaks are found:

1.  **Identify the secret**: The output will show the file path, line number, and the secret string.
2.  **Scrub the secret**:
    *   If the file is tracked, replace the secret with a placeholder (e.g., `your-secret-key`) in the file.
    *   Commit the changes: `git commit -am "Scrub secrets"`
3.  **Historical Clean-up** (if necessary):
    *   If the secret exists in previous commits, you must rewrite history.
    *   Use `git filter-repo --invert-paths --path <file_path> --force` to completely remove the file if possible.
    *   Or use thorough scrubbing techniques.
    *   **Force Push**: `git push --force` is required after rewriting history.

### Verification

Run `gitleaks detect -v` again to confirm no leaks remain.

## Regular Maintenance

*   Run this check before every push or pull request.
*   Update `.gitignore` to exclude sensitivity files like `.env` (unless they are example files with placeholders).
