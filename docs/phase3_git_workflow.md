# Phase 3 Git Workflow

This document outlines the Git workflow for committing the SQL database implementation files from Phase 3.

## Before You Begin

Make sure you're in the root directory of your project:

```bash
cd credit-card-fraud-detection
```

## Create a Feature Branch

1. Create and switch to a new feature branch for Phase 3:

```bash
git checkout -b feature/phase3-sql-implementation
```

## Add and Commit SQL Scripts

1. Add the SQL script files to Git:

```bash
git add sql/create_database.sql
git add sql/import_data.sql
git add sql/analysis_queries.sql
git add sql/run_sql_setup.bat
```

2. Commit these files:

```bash
git commit -m "Add SQL database implementation scripts"
```

## Add and Commit Python SQL Connector Files

1. Add the Python connector scripts:

```bash
git add scripts/sql_connector.py
git add scripts/extract_for_bi.py
```

2. Commit these files:

```bash
git commit -m "Add Python-SQL connector scripts"
```

## Add and Commit Documentation

1. Add the documentation file:

```bash
git add docs/database_setup.md
git add docs/phase3_git_workflow.md
```

2. Commit the documentation:

```bash
git commit -m "Add SQL database setup documentation"
```

## Managing SQL Export Files

SQL exports can be large and aren't typically suitable for version control. Here's how to handle them:

1. Make sure the exports directories are in your `.gitignore` file:

```bash
echo "sql_exports/" >> .gitignore
echo "bi_exports/" >> .gitignore
```

2. Add the updated `.gitignore` file:

```bash
git add .gitignore
git commit -m "Update .gitignore for SQL export directories"
```

## Push Your Branch to GitHub

```bash
git push -u origin feature/phase3-sql-implementation
```

## Create a Pull Request

1. Go to your repository on GitHub
2. Click "Compare & pull request" for your branch
3. Add a description of the SQL database implementation
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
git branch -d feature/phase3-sql-implementation  # Delete the local branch
```

## Important Notes for SQL Files

1. **Connection Strings**: Avoid committing actual connection strings with passwords. Use placeholders or environment variables.

2. **Test & Production Environments**: If you're using different connection parameters for test and production, consider using configuration files that are environment-specific.

3. **SQL Script Parameters**: Review SQL scripts before committing to ensure file paths and server names are parameterized or use relative paths where possible.

4. **Large Data Files**: Avoid committing large SQL data exports or backups to Git. Use `.gitignore` to exclude them.

5. **SQL Server Authentication**: If using SQL Server Authentication (instead of Windows Authentication), ensure you're not storing passwords in scripts.

## Best Practices for SQL Version Control

1. **Script All Changes**: Always create scripts for database changes rather than making direct changes to the database.

2. **Use Migration Scripts**: If the database schema evolves, create numbered migration scripts rather than modifying the original creation script.

3. **Include Rollback Logic**: Where possible, include rollback logic in your SQL scripts to revert changes if needed.

4. **Test Scripts Before Committing**: Ensure all SQL scripts run successfully in a test environment before committing.

5. **Document Database Changes**: Include comments in your SQL scripts and update documentation to reflect database changes.