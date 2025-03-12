# Phase 2 Git Workflow

This document outlines the Git workflow for committing the Python data preparation and analysis scripts from Phase 2.

## Before You Begin

Make sure you're in the root directory of your project:

```bash
cd credit-card-fraud-detection
```

## Create a Feature Branch

1. Create and switch to a new feature branch for Phase 2:

```bash
git checkout -b feature/phase2-python-scripts
```

## Add and Commit Script Files

1. Add the script files to Git:

```bash
git add scripts/config.py
git add scripts/data_cleaning.py
git add scripts/data_analysis.py
git add scripts/model_training.py
git add scripts/data_export.py
git add scripts/run_all.bat
```

2. Add documentation:

```bash
git add docs/phase2_git_workflow.md
```

3. Commit these files:

```bash
git commit -m "Add Python scripts for data preparation and analysis"
```

## Managing Large Data Files

When working with large data files that result from running the scripts:

1. Make sure Git LFS is tracking the appropriate file types:

```bash
git lfs track "*.csv"
git lfs track "*.pkl"
```

2. Add the processed data directory to Git:

```bash
git add data/processed/
```

3. Commit the processed data:

```bash
git commit -m "Add processed data files"
```

## Handling Model Files and Visualizations

1. Track model files:

```bash
git lfs track "*.pkl"
git add models/
git commit -m "Add trained model files"
```

2. Add visualizations:

```bash
git add visualizations/
git commit -m "Add data analysis visualizations"
```

3. Add model analysis outputs:

```bash
git add model_analysis/
git commit -m "Add model analysis results"
```

## Commit Exports for SQL, Excel, and Power BI

```bash
git add exports/
git commit -m "Add data exports for SQL, Excel, and Power BI"
```

## Push Your Branch to GitHub

```bash
git push -u origin feature/phase2-python-scripts
```

## Create a Pull Request

1. Go to your repository on GitHub
2. Click "Compare & pull request" for your branch
3. Add a description of the changes in Phase 2
4. Click "Create pull request"

## Merge the Pull Request

Once the pull request is approved:

1. Click "Merge pull request" on GitHub
2. Click "Confirm merge"
3. Delete the branch if no longer needed

## Update Your Local Repository

After merging on GitHub:

```bash
git checkout main
git pull origin main
git branch -d feature/phase2-python-scripts  # Delete the local branch
```

## Important Notes for Windows Users

1. **Line Endings**: Windows and Unix systems handle line endings differently. Make sure Git is configured properly:

```bash
git config --global core.autocrlf true
```

2. **File Paths**: Windows uses backslashes (`\`) while Git paths typically use forward slashes (`/`). Git usually handles this conversion, but be careful when specifying paths in scripts.

3. **File Permissions**: Windows doesn't handle file permissions the same way as Unix systems. If you're collaborating with users on different operating systems, be aware that executable permissions might not be preserved.

## Best Practices for Python Scripts

1. **Commit Often**: Make small, focused commits that represent logical units of work
2. **Write Meaningful Commit Messages**: Explain why the change was made, not just what was changed
3. **Keep Large Files Out of Git**: Use Git LFS for large files, but consider if they really need to be in version control
4. **Use .gitignore**: Make sure temporary files, logs, and environment-specific files are ignored