@echo off
echo Credit Card Fraud Detection - Running full pipeline
echo ===================================================

echo.
echo Step 1: Data Cleaning
python data_cleaning.py
if %ERRORLEVEL% neq 0 (
    echo Error in data cleaning step!
    exit /b %ERRORLEVEL%
)

echo.
echo Step 2: Data Analysis
python data_analysis.py
if %ERRORLEVEL% neq 0 (
    echo Error in data analysis step!
    exit /b %ERRORLEVEL%
)

echo.
echo Step 3: Model Training
python model_training.py
if %ERRORLEVEL% neq 0 (
    echo Error in model training step!
    exit /b %ERRORLEVEL%
)

echo.
echo Step 4: Data Export
python data_export.py
if %ERRORLEVEL% neq 0 (
    echo Error in data export step!
    exit /b %ERRORLEVEL%
)

echo.
echo All steps completed successfully!
echo Check the logs directory for detailed logs.
echo.
echo Results are available in:
echo - visualizations/ (Data visualizations)
echo - model_analysis/ (Model performance)
echo - exports/ (Data for SQL, Excel, and Power BI)

pause