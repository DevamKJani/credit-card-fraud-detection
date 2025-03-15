# Phase 4 Git Workflow

This document outlines the Git workflow for committing Excel analysis files from Phase 4.

## Before You Begin

Make sure you're in the root directory of your project:

```bash
cd credit-card-fraud-detection
```

## Create a Feature Branch

1. Create and switch to a new feature branch for Phase 4:

```bash
git checkout -b feature/phase4-excel-analysis
```

## Managing Excel Files in Git

Excel files can be challenging to manage in Git because they are binary files. Here's how to handle them effectively:

### Excel Template Files (.xltx)

1. **Add Excel template files to Git**:
   
   Excel template files are valuable to version control since they contain your analysis structure without data:

   ```bash
   git add excel/Fraud_Overview_Template.xlsx
   git add excel/Fraud_Model_Analysis_Template.xlsx
   git add excel/Transaction_Monitoring_Template.xlsx
   ```

2. **Commit template files**:

   ```bash
   git commit -m "Add Excel analysis templates for fraud detection"
   ```

### Excel Macro Files (.bas)

1. **Add Excel macro files to Git**:

   VBA macro files exported as .bas files can be version-controlled as text:

   ```bash
   git add excel/FraudAnalysisMacros.bas
   git add excel/FraudFunctions.bas
   ```

2. **Commit macro files**:

   ```bash
   git commit -m "Add Excel macros and functions for fraud analysis"
   ```

### Excel Documentation

1. **Add documentation files**:

   ```bash
   git add excel/Fraud_Overview_Template.md
   git add excel/Fraud_Model_Analysis_Template.md
   git add excel/Transaction_Monitoring_Template.md
   git add docs/phase4_git_workflow.md
   ```

2. **Commit documentation**:

   ```bash
   git commit -m "Add Excel template documentation"
   ```

### Excluding Data Files

Excel workbooks with actual data should generally not be committed to Git to avoid large binary files:

1. **Update .gitignore file**:

   ```bash
   echo "*.xlsx" >> .gitignore
   echo "!*.xltx" >> .gitignore
   echo "~$*.xlsx" >> .gitignore  # Exclude Excel temp files
   git add .gitignore
   git commit -m "Update .gitignore for Excel files"
   ```

This configuration excludes all Excel files except templates (.xltx).

## Using Git LFS for Large Excel Files (Optional)

If you need to track large Excel files containing important outputs:

1. **Setup Git LFS for Excel files**:

   ```bash
   git lfs install
   git lfs track "*.xlsx"
   git add .gitattributes
   git commit -m "Configure Git LFS for Excel files"
   ```

2. **Add important Excel output files**:

   ```bash
   git add excel/Fraud_Detection_Report.xlsx
   git commit -m "Add fraud detection summary report"
   ```

## Exporting Excel Objects for Version Control

For better version control of Excel content:

1. **Export VBA modules** using the VBA Editor:
   - Open Excel file
   - Press Alt+F11 to open VBA Editor
   - Right-click on a module → Export File
   - Save as .bas file

2. **Export PivotTable definitions** as XML:
   - Create a small text file that documents the structure
   - Include column names, measures, and layout

## Push Your Branch to GitHub

```bash
git push -u origin feature/phase4-excel-analysis
```

## Create a Pull Request

1. Go to your repository on GitHub
2. Click "Compare & pull request" for your branch
3. Add a description of the Excel templates and tools created in Phase 4
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
git branch -d feature/phase4-excel-analysis  # Delete the local branch
```

## Best Practices for Excel Files in Git

1. **Use templates over workbooks**: Store the analysis structure without data
2. **Export VBA code**: Store macros as text files rather than within Excel files
3. **Document formulas**: Maintain text documentation of complex formulas
4. **Keep data out of Git**: Use .gitignore to exclude data-containing workbooks
5. **Use Git LFS selectively**: Only for critical Excel files that must be versioned

## Sharing Excel Files

For sharing Excel files that shouldn't be in Git:

1. Use a shared network drive or SharePoint
2. Consider OneDrive or other cloud storage
3. Export key reports as PDFs and commit those instead