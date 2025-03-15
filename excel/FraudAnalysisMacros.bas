Attribute VB_Name = "FraudAnalysisMacros"
' Credit Card Fraud Detection - Excel Macros
' This module contains macros for enhancing the fraud analysis Excel templates

Option Explicit

' Refresh all data connections and pivot tables
Sub RefreshAllData()
    Dim ws As Worksheet
    Dim pt As PivotTable
    Dim conn As WorkbookConnection
    
    ' Refresh all data connections
    For Each conn In ThisWorkbook.Connections
        conn.Refresh
    Next conn
    
    ' Refresh all pivot tables
    For Each ws In ThisWorkbook.Worksheets
        For Each pt In ws.PivotTables
            pt.RefreshTable
        Next pt
    Next ws
    
    ' Update the last refresh time
    If SheetExists("Overview") Then
        Worksheets("Overview").Range("LastRefreshTime").Value = Now()
    End If
    
    MsgBox "All data connections and pivot tables have been refreshed.", vbInformation
End Sub

' Check if a worksheet exists
Function SheetExists(sheetName As String) As Boolean
    Dim ws As Worksheet
    
    On Error Resume Next
    Set ws = ThisWorkbook.Worksheets(sheetName)
    On Error GoTo 0
    
    SheetExists = Not ws Is Nothing
End Function

' Export the current view to PDF
Sub ExportToPDF()
    Dim pdfPath As String
    Dim activeSheet As Worksheet
    
    Set activeSheet = ActiveSheet
    
    ' Create the PDF file path
    pdfPath = ThisWorkbook.Path & "\" & ThisWorkbook.Name & "_" & activeSheet.Name & "_" & Format(Now(), "yyyymmdd_hhmmss") & ".pdf"
    
    ' Export the active sheet to PDF
    activeSheet.ExportAsFixedFormat Type:=xlTypePDF, Filename:=pdfPath, _
        Quality:=xlQualityStandard, IncludeDocProperties:=True, _
        IgnorePrintAreas:=False, OpenAfterPublish:=True
    
    MsgBox "Report exported to: " & pdfPath, vbInformation
End Sub

' Generate a risk threshold analysis
Sub AnalyzeRiskThresholds()
    Dim ws As Worksheet
    Dim resultsSheet As Worksheet
    Dim threshold As Double
    Dim row As Long
    Dim dataRange As Range
    Dim fraudProbCol As Integer
    Dim actualClassCol As Integer
    Dim i As Long
    
    ' Find or create the results sheet
    If SheetExists("ThresholdAnalysis") Then
        Set resultsSheet = ThisWorkbook.Worksheets("ThresholdAnalysis")
        resultsSheet.Cells.Clear
    Else
        Set resultsSheet = ThisWorkbook.Worksheets.Add(After:=ThisWorkbook.Worksheets(ThisWorkbook.Worksheets.Count))
        resultsSheet.Name = "ThresholdAnalysis"
    End If
    
    ' Set up the results sheet
    With resultsSheet
        .Cells(1, 1).Value = "Threshold"
        .Cells(1, 2).Value = "True Positives"
        .Cells(1, 3).Value = "False Positives"
        .Cells(1, 4).Value = "True Negatives"
        .Cells(1, 5).Value = "False Negatives"
        .Cells(1, 6).Value = "Precision"
        .Cells(1, 7).Value = "Recall"
        .Cells(1, 8).Value = "F1 Score"
        
        ' Format the header
        .Range("A1:H1").Font.Bold = True
        .Range("A1:H1").Interior.Color = RGB(200, 200, 200)
    End With
    
    ' Get the data range from the Transactions sheet
    On Error Resume Next
    Set ws = ThisWorkbook.Worksheets("TransactionData")
    If ws Is Nothing Then
        MsgBox "The TransactionData sheet was not found. Please make sure your data is in a sheet named 'TransactionData'.", vbExclamation
        Exit Sub
    End If
    
    ' Find the relevant columns
    fraudProbCol = 0
    actualClassCol = 0
    For i = 1 To ws.UsedRange.Columns.Count
        If ws.Cells(1, i).Value = "fraud_probability" Then
            fraudProbCol = i
        ElseIf ws.Cells(1, i).Value = "class" Then
            actualClassCol = i
        End If
    Next i
    
    If fraudProbCol = 0 Or actualClassCol = 0 Then
        MsgBox "Could not find required columns 'fraud_probability' and 'class' in the TransactionData sheet.", vbExclamation
        Exit Sub
    End If
    
    ' Get the data range
    Set dataRange = ws.Range(ws.Cells(2, 1), ws.Cells(ws.UsedRange.Rows.Count, ws.UsedRange.Columns.Count))
    
    ' Analyze different thresholds
    row = 2
    For threshold = 0.05 To 0.95 Step 0.05
        Dim TP As Long, FP As Long, TN As Long, FN As Long
        Dim precision As Double, recall As Double, f1 As Double
        
        TP = 0: FP = 0: TN = 0: FN = 0
        
        ' Calculate confusion matrix values
        For i = 1 To dataRange.Rows.Count
            Dim fraudProb As Double, actualClass As Integer
            
            fraudProb = dataRange.Cells(i, fraudProbCol).Value
            actualClass = dataRange.Cells(i, actualClassCol).Value
            
            If fraudProb >= threshold Then
                ' Predicted as fraud
                If actualClass = 1 Then
                    TP = TP + 1
                Else
                    FP = FP + 1
                End If
            Else
                ' Predicted as legitimate
                If actualClass = 1 Then
                    FN = FN + 1
                Else
                    TN = TN + 1
                End If
            End If
        Next i
        
        ' Calculate metrics
        If (TP + FP) > 0 Then
            precision = TP / (TP + FP)
        Else
            precision = 0
        End If
        
        If (TP + FN) > 0 Then
            recall = TP / (TP + FN)
        Else
            recall = 0
        End If
        
        If (precision + recall) > 0 Then
            f1 = 2 * (precision * recall) / (precision + recall)
        Else
            f1 = 0
        End If
        
        ' Add to results
        With resultsSheet
            .Cells(row, 1).Value = threshold
            .Cells(row, 2).Value = TP
            .Cells(row, 3).Value = FP
            .Cells(row, 4).Value = TN
            .Cells(row, 5).Value = FN
            .Cells(row, 6).Value = precision
            .Cells(row, 7).Value = recall
            .Cells(row, 8).Value = f1
        End With
        
        row = row + 1
    Next threshold
    
    ' Format the results
    With resultsSheet
        .Range("A1:H" & row - 1).Borders.LineStyle = xlContinuous
        .Range("A:A").NumberFormat = "0.00"
        .Range("F:H").NumberFormat = "0.000"
        .Columns.AutoFit
        
        ' Create a chart
        Dim chartObj As ChartObject
        Dim cht As Chart
        
        Set chartObj = .ChartObjects.Add(Left:=.Range("J2").Left, Width:=450, Top:=.Range("J2").Top, Height:=250)
        Set cht = chartObj.Chart
        
        With cht
            .SetSourceData Source:=.Parent.Parent.Range("A1:A" & row - 1 & ",F1:H" & row - 1)
            .ChartType = xlLine
            .HasTitle = True
            .ChartTitle.Text = "Precision, Recall, and F1 Score vs. Threshold"
            .Axes(xlCategory).HasTitle = True
            .Axes(xlCategory).AxisTitle.Text = "Threshold"
            .Axes(xlValue).HasTitle = True
            .Axes(xlValue).AxisTitle.Text = "Score"
            .ApplyLayout 3
            .Axes(xlCategory).TickLabels.NumberFormat = "0.00"
            .Axes(xlValue).TickLabels.NumberFormat = "0.00"
            .Legend.Position = xlLegendPositionBottom
        End With
    End With
    
    ' Activate the results sheet
    resultsSheet.Activate
    MsgBox "Threshold analysis complete. The optimal threshold based on F1 score is highlighted.", vbInformation
    
    ' Find and highlight the optimal threshold
    Dim optimalRow As Long
    Dim maxF1 As Double
    
    maxF1 = 0
    For i = 2 To row - 1
        If resultsSheet.Cells(i, 8).Value > maxF1 Then
            maxF1 = resultsSheet.Cells(i, 8).Value
            optimalRow = i
        End If
    Next i
    
    ' Highlight the optimal row
    resultsSheet.Range("A" & optimalRow & ":H" & optimalRow).Interior.Color = RGB(255, 255, 0)
    
    ' Add a note about the optimal threshold
    resultsSheet.Cells(row + 1, 1).Value = "Note: The optimal threshold based on F1 score is " & resultsSheet.Cells(optimalRow, 1).Value
    resultsSheet.Cells(row + 1, 1).Font.Bold = True
End Sub

' Sort a 2D array by a specific column
Sub SortArrayByColumn(arr As Variant, col As Integer, ascending As Boolean)
    Dim i As Long, j As Long
    Dim temp As Variant
    
    For i = LBound(arr, 1) To UBound(arr, 1) - 1
        For j = i + 1 To UBound(arr, 1)
            If ascending Then
                If arr(i, col) > arr(j, col) Then
                    ' Swap entire rows
                    For k = LBound(arr, 2) To UBound(arr, 2)
                        temp = arr(i, k)
                        arr(i, k) = arr(j, k)
                        arr(j, k) = temp
                    Next k
                End If
            Else
                If arr(i, col) < arr(j, col) Then
                    ' Swap entire rows
                    For k = LBound(arr, 2) To UBound(arr, 2)
                        temp = arr(i, k)
                        arr(i, k) = arr(j, k)
                        arr(j, k) = temp
                    Next k
                End If
            End If
        Next j
    Next i
End Sub

' Generate a transaction summary report
Sub GenerateTransactionSummaryReport()
    Dim reportSheet As Worksheet
    Dim dataSheet As Worksheet
    Dim lastRow As Long
    Dim i As Long, k As Long
    
    ' Find the data sheet
    On Error Resume Next
    Set dataSheet = ThisWorkbook.Worksheets("TransactionData")
    If dataSheet Is Nothing Then
        MsgBox "The TransactionData sheet was not found. Please make sure your data is in a sheet named 'TransactionData'.", vbExclamation
        Exit Sub
    End If
    
    ' Create or clear the report sheet
    If SheetExists("TransactionSummary") Then
        Set reportSheet = ThisWorkbook.Worksheets("TransactionSummary")
        reportSheet.Cells.Clear
    Else
        Set reportSheet = ThisWorkbook.Worksheets.Add(After:=ThisWorkbook.Worksheets(ThisWorkbook.Worksheets.Count))
        reportSheet.Name = "TransactionSummary"
    End If
    
    ' Set up the report header
    With reportSheet
        .Cells(1, 1).Value = "Credit Card Fraud Detection - Transaction Summary"
        .Range("A1:L1").Merge
        .Range("A1").Font.Size = 14
        .Range("A1").Font.Bold = True
        .Range("A1").HorizontalAlignment = xlCenter
        
        .Cells(2, 1).Value = "Generated on: " & Format(Now(), "yyyy-mm-dd hh:mm:ss")
        .Range("A2:L2").Merge
        .Range("A2").HorizontalAlignment = xlCenter
        
        .Cells(4, 1).Value = "Transaction Statistics"
        .Range("A4").Font.Bold = True
        
        .Cells(5, 1).Value = "Total Transactions:"
        .Cells(5, 2).Value = dataSheet.UsedRange.Rows.Count - 1
        
        .Cells(6, 1).Value = "Legitimate Transactions:"
        .Cells(6, 2).Formula = "=COUNTIFS(TransactionData!class,0)"
        
        .Cells(7, 1).Value = "Fraudulent Transactions:"
        .Cells(7, 2).Formula = "=COUNTIFS(TransactionData!class,1)"
        
        .Cells(8, 1).Value = "Fraud Rate:"
        .Cells(8, 2).Formula = "=COUNTIFS(TransactionData!class,1)/COUNTA(TransactionData!class)"
        .Cells(8, 2).NumberFormat = "0.00%"
        
        .Cells(10, 1).Value = "Model Performance"
        .Range("A10").Font.Bold = True
        
        .Cells(11, 1).Value = "True Positives:"
        .Cells(11, 2).Formula = "=COUNTIFS(TransactionData!class,1,TransactionData!predicted_fraud,1)"
        
        .Cells(12, 1).Value = "False Positives:"
        .Cells(12, 2).Formula = "=COUNTIFS(TransactionData!class,0,TransactionData!predicted_fraud,1)"
        
        .Cells(13, 1).Value = "True Negatives:"
        .Cells(13, 2).Formula = "=COUNTIFS(TransactionData!class,0,TransactionData!predicted_fraud,0)"
        
        .Cells(14, 1).Value = "False Negatives:"
        .Cells(14, 2).Formula = "=COUNTIFS(TransactionData!class,1,TransactionData!predicted_fraud,0)"
        
        .Cells(15, 1).Value = "Precision:"
        .Cells(15, 2).Formula = "=IF(B11+B12=0,0,B11/(B11+B12))"
        .Cells(15, 2).NumberFormat = "0.00%"
        
        .Cells(16, 1).Value = "Recall:"
        .Cells(16, 2).Formula = "=IF(B11+B14=0,0,B11/(B11+B14))"
        .Cells(16, 2).NumberFormat = "0.00%"
        
        .Cells(17, 1).Value = "F1 Score:"
        .Cells(17, 2).Formula = "=IF(B15+B16=0,0,2*(B15*B16)/(B15+B16))"
        .Cells(17, 2).NumberFormat = "0.00%"
        
        .Cells(18, 1).Value = "Accuracy:"
        .Cells(18, 2).Formula = "=(B11+B13)/(B11+B12+B13+B14)"
        .Cells(18, 2).NumberFormat = "0.00%"
        
        ' Create headers for high-risk transactions
        .Cells(20, 1).Value = "Top 10 Highest Risk Transactions"
        .Range("A20").Font.Bold = True
        
        .Cells(21, 1).Value = "Transaction ID"
        .Cells(21, 2).Value = "Date/Time"
        .Cells(21, 3).Value = "Amount"
        .Cells(21, 4).Value = "Risk Score"
        .Cells(21, 5).Value = "Actual Class"
        .Cells(21, 6).Value = "Predicted Fraud"
        .Range("A21:F21").Font.Bold = True
        .Range("A21:F21").Interior.Color = RGB(200, 200, 200)
    End With
    
    ' Generate a list of top 10 highest risk transactions
    ' This requires sorting the data by risk score
    lastRow = dataSheet.UsedRange.Rows.Count
    
    ' Create a temporary array to store the high-risk transactions
    Dim highRiskData() As Variant
    ReDim highRiskData(1 To lastRow - 1, 1 To 6)
    
    ' Find the column indices
    Dim idCol As Integer, dateCol As Integer, amountCol As Integer
    Dim riskCol As Integer, classCol As Integer, predCol As Integer
    
    For i = 1 To dataSheet.UsedRange.Columns.Count
        Select Case dataSheet.Cells(1, i).Value
            Case "transaction_id": idCol = i
            Case "transaction_date": dateCol = i
            Case "amount": amountCol = i
            Case "fraud_probability": riskCol = i
            Case "class": classCol = i
            Case "predicted_fraud": predCol = i
        End Select
    Next i
    
    ' Fill the array with data
    For i = 1 To lastRow - 1
        highRiskData(i, 1) = dataSheet.Cells(i + 1, idCol).Value
        highRiskData(i, 2) = dataSheet.Cells(i + 1, dateCol).Value
        highRiskData(i, 3) = dataSheet.Cells(i + 1, amountCol).Value
        highRiskData(i, 4) = dataSheet.Cells(i + 1, riskCol).Value
        highRiskData(i, 5) = dataSheet.Cells(i + 1, classCol).Value
        highRiskData(i, 6) = dataSheet.Cells(i + 1, predCol).Value
    Next i
    
    ' Sort the array by risk score (descending)
    SortArrayByColumn highRiskData, 4, False
    
    ' Add the top 10 to the report
    For i = 1 To Application.Min(10, lastRow - 1)
        reportSheet.Cells(21 + i, 1).Value = highRiskData(i, 1)
        reportSheet.Cells(21 + i, 2).Value = highRiskData(i, 2)
        reportSheet.Cells(21 + i, 3).Value = highRiskData(i, 3)
        reportSheet.Cells(21 + i, 4).Value = highRiskData(i, 4)
        reportSheet.Cells(21 + i, 5).Value = highRiskData(i, 5)
        reportSheet.Cells(21 + i, 6).Value = highRiskData(i, 6)
    Next i
    
    ' Format the results
    With reportSheet
        .Range("A21:F" & 21 + Application.Min(10, lastRow - 1)).Borders.LineStyle = xlContinuous
        .Columns("A:F").AutoFit
        
        ' Apply conditional formatting to the risk scores
        Dim cfRange As Range
        Set cfRange = .Range("D22:D" & 21 + Application.Min(10, lastRow - 1))
        
        ' Red for high risk
        cfRange.FormatConditions.Add Type:=xlCellValue, Operator:=xlGreaterEqual, Formula1:=0.7
        cfRange.FormatConditions(1).Interior.Color = RGB(255, 153, 153)
        
        ' Yellow for medium risk
        cfRange.FormatConditions.Add Type:=xlCellValue, Operator:=xlAnd, Formula1:=0.3, Formula2:=0.7
        cfRange.FormatConditions(2).Interior.Color = RGB(255, 255, 153)
        
        ' Green for low risk
        cfRange.FormatConditions.Add Type:=xlCellValue, Operator:=xlLess, Formula1:=0.3
        cfRange.FormatConditions(3).Interior.Color = RGB(153, 255, 153)
    End With
    
    ' Create a chart showing the distribution of risk scores
    With reportSheet
        ' Add a risk score distribution chart
        .Cells(33, 1).Value = "Risk Score Distribution"
        .Range("A33").Font.Bold = True
        
        ' Create bins for risk scores
        Dim bins(10) As Double
        For i = 0 To 10
            bins(i) = i / 10
        Next i
        
        ' Count risk scores in each bin
        Dim binCounts(10) As Long
        For i = 1 To lastRow - 1
            Dim riskScore As Double
            riskScore = dataSheet.Cells(i + 1, riskCol).Value
            For j = 1 To 10
                If riskScore <= bins(j) Then
                    binCounts(j) = binCounts(j) + 1
                    Exit For
                End If
            Next j
        Next i
        
        ' Add the bin data to the sheet
        .Cells(34, 1).Value = "Risk Range"
        .Cells(34, 2).Value = "Count"
        .Range("A34:B34").Font.Bold = True
        
        For i = 1 To 10
            .Cells(34 + i, 1).Value = bins(i - 1) & " - " & bins(i)
            .Cells(34 + i, 2).Value = binCounts(i)
        Next i
        
        ' Create a chart
        Dim chartObj As ChartObject
        Dim cht As Chart
        
        Set chartObj = .ChartObjects.Add(Left:=.Range("D33").Left, Width:=400, Top:=.Range("D33").Top, Height:=200)
        Set cht = chartObj.Chart
        
        With cht
            .SetSourceData Source:=reportSheet.Range("A35:B44")
            .ChartType = xlColumnClustered
            .HasTitle = True
            .ChartTitle.Text = "Risk Score Distribution"
            .Axes(xlCategory).HasTitle = True
            .Axes(xlCategory).AxisTitle.Text = "Risk Score Range"
            .Axes(xlValue).HasTitle = True
            .Axes(xlValue).AxisTitle.Text = "Transaction Count"
        End With
    End With
    
    ' Activate the report sheet
    reportSheet.Activate
    MsgBox "Transaction summary report generated successfully.", vbInformation
End Sub

' Create a dashboard with fraud detection metrics
Sub CreateFraudDashboard()
    Dim dashSheet As Worksheet
    Dim dataSheet As Worksheet
    
    ' Find the data sheet
    On Error Resume Next
    Set dataSheet = ThisWorkbook.Worksheets("TransactionData")
    If dataSheet Is Nothing Then
        MsgBox "The TransactionData sheet was not found. Please make sure your data is in a sheet named 'TransactionData'.", vbExclamation
        Exit Sub
    End If
    
    ' Create or clear the dashboard sheet
    If SheetExists("Dashboard") Then
        Set dashSheet = ThisWorkbook.Worksheets("Dashboard")
        dashSheet.Cells.Clear
    Else
        Set dashSheet = ThisWorkbook.Worksheets.Add(After:=ThisWorkbook.Worksheets(ThisWorkbook.Worksheets.Count))
        dashSheet.Name = "Dashboard"
    End If
    
    ' Set up the dashboard
    With dashSheet
        ' Title
        .Cells(1, 1).Value = "Credit Card Fraud Detection Dashboard"
        .Range("A1:J1").Merge
        .Range("A1").Font.Size = 16
        .Range("A1").Font.Bold = True
        .Range("A1").HorizontalAlignment = xlCenter
        
        ' Last updated timestamp
        .Cells(2, 1).Value = "Last Updated: " & Format(Now(), "yyyy-mm-dd hh:mm:ss")
        .Range("A2:J2").Merge
        .Range("A2").HorizontalAlignment = xlCenter
        
        ' Create KPI section
        .Cells(4, 1).Value = "Key Performance Indicators"
        .Range("A4").Font.Bold = True
        
        ' KPI boxes
        ' Box 1: Total Transactions
        .Range("B5:D8").Merge
        .Range("B5").Value = "Total Transactions"
        .Range("B5").Font.Bold = True
        .Range("B5").HorizontalAlignment = xlCenter
        
        .Range("B6:D8").Merge
        .Range("B6").Value = Application.WorksheetFunction.CountA(dataSheet.Range("A:A")) - 1
        .Range("B6").Font.Size = 24
        .Range("B6").HorizontalAlignment = xlCenter
        .Range("B6").VerticalAlignment = xlCenter
        
        ' Box 2: Fraud Rate
        .Range("E5:G8").Merge
        .Range("E5").Value = "Fraud Rate"
        .Range("E5").Font.Bold = True
        .Range("E5").HorizontalAlignment = xlCenter
        
        .Range("E6:G8").Merge
        .Range("E6").Formula = "=COUNTIFS(TransactionData!class,1)/COUNTA(TransactionData!class)"
        .Range("E6").NumberFormat = "0.00%"
        .Range("E6").Font.Size = 24
        .Range("E6").HorizontalAlignment = xlCenter
        .Range("E6").VerticalAlignment = xlCenter
        
        ' Box 3: Model Accuracy
        .Range("H5:J8").Merge
        .Range("H5").Value = "Model Accuracy"
        .Range("H5").Font.Bold = True
        .Range("H5").HorizontalAlignment = xlCenter
        
        .Range("H6:J8").Merge
        .Range("H6").Formula = "=(COUNTIFS(TransactionData!class,1,TransactionData!predicted_fraud,1) + COUNTIFS(TransactionData!class,0,TransactionData!predicted_fraud,0)) / COUNTA(TransactionData!class)"
        .Range("H6").NumberFormat = "0.00%"
        .Range("H6").Font.Size = 24
        .Range("H6").HorizontalAlignment = xlCenter
        .Range("H6").VerticalAlignment = xlCenter
        
        ' Create charts section
        .Cells(10, 1).Value = "Fraud Analysis Charts"
        .Range("A10").Font.Bold = True
        
        ' Chart 1: Class Distribution Pie Chart
        Dim chartObj1 As ChartObject
        Dim cht1 As Chart
        
        ' Generate data for the chart
        .Cells(20, 1).Value = "Class"
        .Cells(20, 2).Value = "Count"
        .Cells(21, 1).Value = "Legitimate"
        .Cells(21, 2).Formula = "=COUNTIFS(TransactionData!class,0)"
        .Cells(22, 1).Value = "Fraudulent"
        .Cells(22, 2).Formula = "=COUNTIFS(TransactionData!class,1)"
        
        Set chartObj1 = .ChartObjects.Add(Left:=.Range("B11").Left, Width:=300, Top:=.Range("B11").Top, Height:=200)
        Set cht1 = chartObj1.Chart
        
        With cht1
            .SetSourceData Source:=dashSheet.Range("A21:B22")
            .ChartType = xlPie
            .HasTitle = True
            .ChartTitle.Text = "Transaction Class Distribution"
            .ApplyLayout 3
            .SetElement (msoElementLegendRight)
        End With
        
        ' Chart 2: Risk Score Distribution
        Dim chartObj2 As ChartObject
        Dim cht2 As Chart
        
        ' Generate data for the chart - using bins
        .Cells(24, 1).Value = "Risk Range"
        .Cells(24, 2).Value = "Count"
        
        ' Define bins
        Dim bins(5) As String
        bins(0) = "0.0-0.2"
        bins(1) = "0.2-0.4"
        bins(2) = "0.4-0.6"
        bins(3) = "0.6-0.8"
        bins(4) = "0.8-1.0"
        
        ' Calculate bin counts with formulas
        For i = 0 To 4
            .Cells(25 + i, 1).Value = bins(i)
            
            Dim lowerBound As Double, upperBound As Double
            lowerBound = CDbl(Left(bins(i), 3))
            upperBound = CDbl(Right(bins(i), 3))
            
            ' Create COUNTIFS formula
            If i < 4 Then
                .Cells(25 + i, 2).Formula = "=COUNTIFS(TransactionData!fraud_probability,">=" & lowerBound & ",TransactionData!fraud_probability,"<" & upperBound & ")"
            Else
                .Cells(25 + i, 2).Formula = "=COUNTIFS(TransactionData!fraud_probability,">=" & lowerBound & ",TransactionData!fraud_probability,"<=" & upperBound & ")"
            End If
        Next i
        
        Set chartObj2 = .ChartObjects.Add(Left:=.Range("G11").Left, Width:=300, Top:=.Range("G11").Top, Height:=200)
        Set cht2 = chartObj2.Chart
        
        With cht2
            .SetSourceData Source:=dashSheet.Range("A25:B29")
            .ChartType = xlColumnClustered
            .HasTitle = True
            .ChartTitle.Text = "Risk Score Distribution"
            .Axes(xlCategory).HasTitle = True
            .Axes(xlCategory).AxisTitle.Text = "Risk Score Range"
            .Axes(xlValue).HasTitle = True
            .Axes(xlValue).AxisTitle.Text = "Count"
        End With
        
        ' Add dashboard controls section
        .Cells(32, 1).Value = "Dashboard Controls"
        .Range("A32").Font.Bold = True
        
        ' Add refresh button
            Dim btnRefresh As Button
            Set btnRefresh = .Buttons.Add(Left:=.Range("B33").Left, Top:=.Range("B33").Top, Width:=100, Height:=30)
            With btnRefresh
                .Caption = "Refresh Data"
                .OnAction = "RefreshAllData"
                .Name = "btnRefresh"
            End With
            
            ' Add export button
            Dim btnExport As Button
            Set btnExport = .Buttons.Add(Left:=.Range("D33").Left, Top:=.Range("D33").Top, Width:=100, Height:=30)
            With btnExport
                .Caption = "Export to PDF"
                .OnAction = "ExportToPDF"
                .Name = "btnExport"
            End With
            
            ' Add analysis button
            Dim btnAnalysis As Button
            Set btnAnalysis = .Buttons.Add(Left:=.Range("F33").Left, Top:=.Range("F33").Top, Width:=140, Height:=30)
            With btnAnalysis
                .Caption = "Analyze Thresholds"
                .OnAction = "AnalyzeRiskThresholds"
                .Name = "btnAnalysis"
            End With
            
            ' Add report button
            Dim btnReport As Button
            Set btnReport = .Buttons.Add(Left:=.Range("H33").Left, Top:=.Range("H33").Top, Width:=140, Height:=30)
            With btnReport
                .Caption = "Generate Report"
                .OnAction = "GenerateTransactionSummaryReport"
                .Name = "btnReport"
            End With
            
            ' Format the dashboard with borders and colors
            ' KPI boxes
            .Range("B5:D8").BorderAround ColorIndex:=1, Weight:=xlMedium
            .Range("B5:D8").Interior.Color = RGB(220, 230, 241)
            
            .Range("E5:G8").BorderAround ColorIndex:=1, Weight:=xlMedium
            .Range("E5:G8").Interior.Color = RGB(220, 230, 241)
            
            .Range("H5:J8").BorderAround ColorIndex:=1, Weight:=xlMedium
            .Range("H5:J8").Interior.Color = RGB(220, 230, 241)
            
            ' Add conditional formatting for fraud rate KPI
            .Range("E6:G8").FormatConditions.Add Type:=xlCellValue, Operator:=xlGreater, Formula1:=0.01
            .Range("E6:G8").FormatConditions(1).Interior.Color = RGB(255, 200, 200)
            
            ' Add conditional formatting for model accuracy KPI
            .Range("H6:J8").FormatConditions.Add Type:=xlCellValue, Operator:=xlLess, Formula1:=0.95
            .Range("H6:J8").FormatConditions(1).Interior.Color = RGB(255, 200, 200)
            
            ' Hide the data tables used for charts
            .Range("A20:B29").Font.ColorIndex = 2  ' White text color, effectively hiding it
            
            ' Activate the dashboard and show a completion message
            .Activate
            .Range("A1").Select
            MsgBox "Fraud Detection Dashboard created successfully.", vbInformation
        End With
        End Sub

        ' Create time-based analysis pivot table
        Sub CreateTimePivotAnalysis()
            Dim pivotSheet As Worksheet
            Dim dataSheet As Worksheet
            Dim pvtCache As PivotCache
            Dim pvt As PivotTable
            Dim dataRange As Range
            
            ' Find the data sheet
            On Error Resume Next
            Set dataSheet = ThisWorkbook.Worksheets("TransactionData")
            If dataSheet Is Nothing Then
                MsgBox "The TransactionData sheet was not found. Please make sure your data is in a sheet named 'TransactionData'.", vbExclamation
                Exit Sub
            End If
            
            ' Create or clear the pivot sheet
            If SheetExists("TimePivotAnalysis") Then
                Set pivotSheet = ThisWorkbook.Worksheets("TimePivotAnalysis")
                pivotSheet.Cells.Clear
            Else
                Set pivotSheet = ThisWorkbook.Worksheets.Add(After:=ThisWorkbook.Worksheets(ThisWorkbook.Worksheets.Count))
                pivotSheet.Name = "TimePivotAnalysis"
            End If
            
            ' Determine data range
            Set dataRange = dataSheet.UsedRange
            
            ' Create pivot cache
            Set pvtCache = ThisWorkbook.PivotCaches.Create(SourceType:=xlDatabase, SourceData:=dataRange)
            
            ' Create pivot table
            Set pvt = pvtCache.CreatePivotTable(TableDestination:=pivotSheet.Range("B5"), TableName:="TimePivotTable")
            
            ' Configure pivot table
            With pvt
                ' Add transaction hour to row field
                .AddFields RowFields:="Hour", ColumnFields:=""
                
                ' Add transaction count to data field
                .AddDataField .PivotFields("transaction_id"), "Transaction Count", xlCount
                
                ' Add sum of amount to data field
                .AddDataField .PivotFields("amount"), "Total Amount", xlSum
                
                ' Add fraud count to data field
                .AddDataField .PivotFields("class"), "Fraud Count", xlSum
                
                ' Calculate fraud rate
                .CalculatedFields.Add Name:="Fraud Rate", Formula:="='Fraud Count'/'Transaction Count'"
                .AddDataField .PivotFields("Fraud Rate"), "Fraud Rate", xlSum
                .PivotFields("Fraud Rate").NumberFormat = "0.00%"
                
                ' Format settings
                .DisplayFieldCaptions = True
                .ShowTableStyleRowStripes = True
                .TableStyle2 = "PivotStyleMedium2"
            End With
            
            ' Create pivot chart
            Dim chartObj As ChartObject
            Dim cht As Chart
            
            Set chartObj = pivotSheet.ChartObjects.Add(Left:=pivotSheet.Range("H5").Left, Width:=450, Top:=pivotSheet.Range("H5").Top, Height:=250)
            Set cht = chartObj.Chart
            
            With cht
                .SetSourceData Source:=pvt.TableRange1
                .ChartType = xlColumnClustered
                .HasTitle = True
                .ChartTitle.Text = "Transaction and Fraud Analysis by Hour"
                .SetElement (msoElementLegendBottom)
                .SetElement (msoElementPrimaryValueAxisTitle)
                .Axes(xlValue).AxisTitle.Text = "Count"
                .SetElement (msoElementPrimaryCategoryAxisTitle)
                .Axes(xlCategory).AxisTitle.Text = "Hour of Day"
            End With
            
            ' Add a secondary chart for fraud rate
            Dim chartObj2 As ChartObject
            Dim cht2 As Chart
            
            Set chartObj2 = pivotSheet.ChartObjects.Add(Left:=pivotSheet.Range("H25").Left, Width:=450, Top:=pivotSheet.Range("H25").Top, Height:=250)
            Set cht2 = chartObj2.Chart
            
            With cht2
                .SetSourceData Source:=pvt.TableRange1
                .ChartType = xlLineMarkers
                .HasTitle = True
                .ChartTitle.Text = "Fraud Rate by Hour"
                .SetElement (msoElementLegendBottom)
                .SetElement (msoElementPrimaryValueAxisTitle)
                .Axes(xlValue).AxisTitle.Text = "Fraud Rate"
                .Axes(xlValue).TickLabels.NumberFormat = "0.00%"
                .SetElement (msoElementPrimaryCategoryAxisTitle)
                .Axes(xlCategory).AxisTitle.Text = "Hour of Day"
            End With
            
            ' Add explanation and title
            With pivotSheet
                .Cells(1, 2).Value = "Time-Based Fraud Analysis"
                .Range("B1").Font.Size = 14
                .Range("B1").Font.Bold = True
                
                .Cells(2, 2).Value = "This analysis shows transaction patterns and fraud rates by hour of day."
                .Cells(3, 2).Value = "Generated on: " & Format(Now(), "yyyy-mm-dd hh:mm:ss")
                
                ' Add instructions
                .Cells(55, 2).Value = "Instructions:"
                .Range("B55").Font.Bold = True
                .Cells(56, 2).Value = "1. Use pivot table filters to explore different time segments"
                .Cells(57, 2).Value = "2. Right-click on pivot table and select 'Refresh' to update data"
                .Cells(58, 2).Value = "3. Explore hourly patterns to identify peak fraud times"
            End With
            
            ' Activate the pivot sheet
            pivotSheet.Activate
            pivotSheet.Range("B1").Select
            MsgBox "Time-based pivot analysis created successfully. You can filter and analyze fraud patterns by hour.", vbInformation
        End Sub

        ' Create amount-based analysis
        Sub CreateAmountAnalysis()
            Dim amountSheet As Worksheet
            Dim dataSheet As Worksheet
            Dim lastRow As Long
            Dim i As Long
            
            ' Find the data sheet
            On Error Resume Next
            Set dataSheet = ThisWorkbook.Worksheets("TransactionData")
            If dataSheet Is Nothing Then
                MsgBox "The TransactionData sheet was not found. Please make sure your data is in a sheet named 'TransactionData'.", vbExclamation
                Exit Sub
            End If
            
            ' Create or clear the amount analysis sheet
            If SheetExists("AmountAnalysis") Then
                Set amountSheet = ThisWorkbook.Worksheets("AmountAnalysis")
                amountSheet.Cells.Clear
            Else
                Set amountSheet = ThisWorkbook.Worksheets.Add(After:=ThisWorkbook.Worksheets(ThisWorkbook.Worksheets.Count))
                amountSheet.Name = "AmountAnalysis"
            End If
            
            ' Set up the analysis sheet
            With amountSheet
                .Cells(1, 1).Value = "Credit Card Fraud Detection - Amount Analysis"
                .Range("A1:G1").Merge
                .Range("A1").Font.Size = 14
                .Range("A1").Font.Bold = True
                .Range("A1").HorizontalAlignment = xlCenter
                
                .Cells(2, 1).Value = "Generated on: " & Format(Now(), "yyyy-mm-dd hh:mm:ss")
                .Range("A2:G2").Merge
                .Range("A2").HorizontalAlignment = xlCenter
                
                ' Create amount range analysis
                .Cells(4, 1).Value = "Amount Range Analysis"
                .Range("A4").Font.Bold = True
                
                ' Setup headers for amount range table
                .Cells(5, 1).Value = "Amount Range"
                .Cells(5, 2).Value = "Transaction Count"
                .Cells(5, 3).Value = "Percent of Total"
                .Cells(5, 4).Value = "Fraud Count"
                .Cells(5, 5).Value = "Fraud Rate"
                .Cells(5, 6).Value = "Average Amount"
                .Range("A5:F5").Font.Bold = True
                .Range("A5:F5").Interior.Color = RGB(200, 200, 200)
                
                ' Define amount ranges
                Dim ranges(6) As String
                ranges(0) = "< $10"
                ranges(1) = "$10 - $49.99"
                ranges(2) = "$50 - $99.99"
                ranges(3) = "$100 - $499.99"
                ranges(4) = "$500 - $999.99"
                ranges(5) = ">= $1000"
                
                ' Define range boundaries
                Dim rangeBounds(6) As Double
                rangeBounds(0) = 0
                rangeBounds(1) = 10
                rangeBounds(2) = 50
                rangeBounds(3) = 100
                rangeBounds(4) = 500
                rangeBounds(5) = 1000
                rangeBounds(6) = 1000000  ' Large upper bound
                
                ' Add formulas for each range
                For i = 0 To 5
                    .Cells(6 + i, 1).Value = ranges(i)
                    
                    ' Transaction count
                    If i < 5 Then
                        .Cells(6 + i, 2).Formula = "=COUNTIFS(TransactionData!amount,">=" & rangeBounds(i) & ",TransactionData!amount,"<" & rangeBounds(i + 1) & ")"
                    Else
                        .Cells(6 + i, 2).Formula = "=COUNTIFS(TransactionData!amount,">=" & rangeBounds(i) & ")"
                    End If
                    
                    ' Percent of total
                    .Cells(6 + i, 3).Formula = "=B" & (6 + i) & "/SUM(B6:B11)"
                    .Cells(6 + i, 3).NumberFormat = "0.00%"
                    
                    ' Fraud count
                    If i < 5 Then
                        .Cells(6 + i, 4).Formula = "=COUNTIFS(TransactionData!amount,">=" & rangeBounds(i) & ",TransactionData!amount,"<" & rangeBounds(i + 1) & ",TransactionData!class,1)"
                    Else
                        .Cells(6 + i, 4).Formula = "=COUNTIFS(TransactionData!amount,">=" & rangeBounds(i) & ",TransactionData!class,1)"
                    End If
                    
                    ' Fraud rate
                    .Cells(6 + i, 5).Formula = "=IF(B" & (6 + i) & "=0,0,D" & (6 + i) & "/B" & (6 + i) & ")"
                    .Cells(6 + i, 5).NumberFormat = "0.00%"
                    
                    ' Average amount
                    If i < 5 Then
                        .Cells(6 + i, 6).Formula = "=AVERAGEIFS(TransactionData!amount,TransactionData!amount,">=" & rangeBounds(i) & ",TransactionData!amount,"<" & rangeBounds(i + 1) & ")"
                    Else
                        .Cells(6 + i, 6).Formula = "=AVERAGEIFS(TransactionData!amount,TransactionData!amount,">=" & rangeBounds(i) & ")"
                    End If
                    .Cells(6 + i, 6).NumberFormat = "$#,##0.00"
                Next i
                
                ' Add totals row
                .Cells(12, 1).Value = "Total"
                .Cells(12, 1).Font.Bold = True
                .Cells(12, 2).Formula = "=SUM(B6:B11)"
                .Cells(12, 3).Value = "100.00%"
                .Cells(12, 4).Formula = "=SUM(D6:D11)"
                .Cells(12, 5).Formula = "=D12/B12"
                .Cells(12, 5).NumberFormat = "0.00%"
                .Cells(12, 6).Formula = "=AVERAGE(TransactionData!amount)"
                .Cells(12, 6).NumberFormat = "$#,##0.00"
                
                ' Format the table
                .Range("A5:F12").Borders.LineStyle = xlContinuous
                .Range("A12:F12").Font.Bold = True
                .Range("A12:F12").Interior.Color = RGB(240, 240, 240)
                
                ' Create a chart for transaction distribution by amount
                Dim chartObj As ChartObject
                Dim cht As Chart
                
                Set chartObj = .ChartObjects.Add(Left:=.Range("A14").Left, Width:=350, Top:=.Range("A14").Top, Height:=250)
                Set cht = chartObj.Chart
                
                With cht
                    .SetSourceData Source:=amountSheet.Range("A6:C11")
                    .ChartType = xlColumnClustered
                    .HasTitle = True
                    .ChartTitle.Text = "Transaction Distribution by Amount"
                    .Axes(xlCategory).HasTitle = True
                    .Axes(xlCategory).AxisTitle.Text = "Amount Range"
                    .Axes(xlValue).HasTitle = True
                    .Axes(xlValue).AxisTitle.Text = "Transaction Count"
                    .Legend.Delete
                    .SeriesCollection(1).Delete  ' Delete the range labels series
                End With
                
                ' Create a chart for fraud rate by amount
                Dim chartObj2 As ChartObject
                Dim cht2 As Chart
                
                Set chartObj2 = .ChartObjects.Add(Left:=.Range("H14").Left, Width:=350, Top:=.Range("H14").Top, Height:=250)
                Set cht2 = chartObj2.Chart
                
                With cht2
                    .SetSourceData Source:=amountSheet.Range("A6:A11,E6:E11")
                    .ChartType = xlColumnClustered
                    .HasTitle = True
                    .ChartTitle.Text = "Fraud Rate by Amount Range"
                    .Axes(xlCategory).HasTitle = True
                    .Axes(xlCategory).AxisTitle.Text = "Amount Range"
                    .Axes(xlValue).HasTitle = True
                    .Axes(xlValue).AxisTitle.Text = "Fraud Rate"
                    .Axes(xlValue).TickLabels.NumberFormat = "0.00%"
                    .Legend.Delete
                End With
                
                ' Add analysis section
                .Cells(30, 1).Value = "Key Insights"
                .Range("A30").Font.Bold = True
                
                ' Find the range with highest fraud rate
                .Cells(31, 1).Formula = "Range with highest fraud rate:"
                .Cells(31, 2).Formula = "=INDEX(A6:A11,MATCH(MAX(E6:E11),E6:E11,0))"
                
                ' Calculate average fraud amount
                .Cells(32, 1).Formula = "Average fraudulent transaction amount:"
                .Cells(32, 2).Formula = "=AVERAGEIFS(TransactionData!amount,TransactionData!class,1)"
                .Cells(32, 2).NumberFormat = "$#,##0.00"
                
                ' Calculate average legitimate amount
                .Cells(33, 1).Formula = "Average legitimate transaction amount:"
                .Cells(33, 2).Formula = "=AVERAGEIFS(TransactionData!amount,TransactionData!class,0)"
                .Cells(33, 2).NumberFormat = "$#,##0.00"
                
                ' Calculate fraud amount ratio
                .Cells(34, 1).Formula = "Fraud/legitimate amount ratio:"
                .Cells(34, 2).Formula = "=B32/B33"
                .Cells(34, 2).NumberFormat = "0.00x"
            End With
            
            ' Activate the amount analysis sheet
            amountSheet.Activate
            amountSheet.Range("A1").Select
            MsgBox "Amount analysis completed successfully. The sheet shows transaction patterns by amount range.", vbInformation
        End Sub

        ' Export data for Power BI
        Sub ExportForPowerBI()
            Dim dataSheet As Worksheet
            Dim exportPath As String
            
            ' Find the data sheet
            On Error Resume Next
            Set dataSheet = ThisWorkbook.Worksheets("TransactionData")
            If dataSheet Is Nothing Then
                MsgBox "The TransactionData sheet was not found. Please make sure your data is in a sheet named 'TransactionData'.", vbExclamation
                Exit Sub
            End If
            
            ' Create export path
            exportPath = ThisWorkbook.Path & "\PowerBI_Export_" & Format(Now(), "yyyymmdd_hhmmss") & ".csv"
            
            ' Export the data
            dataSheet.Copy
            ActiveWorkbook.SaveAs Filename:=exportPath, FileFormat:=xlCSV
            ActiveWorkbook.Close SaveChanges:=False
            
            MsgBox "Data exported for Power BI to: " & exportPath, vbInformation
        End Sub