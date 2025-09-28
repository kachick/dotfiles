# Shell Dependencies

This directory contains shell script snippets, such as completions, that are sourced by shell startup files (e.g., `.zshrc`).

## Purpose

The main goals for managing these scripts separately are:

-   **Performance:** To avoid loading entire Nix packages during shell startup just to get completion scripts. This helps keep the shell startup time fast.
-   **Flexibility:** To manage scripts whose paths are not guaranteed to be stable within Nix packages. This provides a workaround in case upstream packages change their file structure.

## Guidelines

-   **Directory Name:** The name `dependencies` was chosen to avoid conflicts with the `vendor` directory used by Go.
-   **Platform Differences:** Scripts here might behave differently across operating systems. When creating or updating scripts, prefer targeting the Linux environment over macOS (Darwin) if a choice must be made.
-   **File Naming:** Maintain a consistent naming convention for files to ensure they can be reliably sourced by shell startup scripts.