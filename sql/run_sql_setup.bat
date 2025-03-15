@echo off
echo Credit Card Fraud Detection - SQL Database Setup
echo ===================================================

echo.
echo Step 1: Creating the database and tables
"C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\sqlcmd" -S localhost\SQLEXPRESS -E -i create_database.sql
if %ERRORLEVEL% neq 0 (
    echo Error creating database!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Step 2: Importing data
"C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\sqlcmd" -S localhost\SQLEXPRESS -E -i import_data.sql
if %ERRORLEVEL% neq 0 (
    echo Error importing data!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Step 3: Creating analysis queries and stored procedures
"C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\sqlcmd" -S localhost\SQLEXPRESS -E -i analysis_queries.sql
if %ERRORLEVEL% neq 0 (
    echo Error creating analysis queries!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo SQL setup completed successfully!
echo Database is ready for use.
echo.

pause