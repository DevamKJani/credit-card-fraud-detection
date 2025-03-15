Attribute VB_Name = "FraudFunctions"
' Credit Card Fraud Detection - Custom Excel Functions
' This module contains custom functions for fraud analysis

Option Explicit

' Calculate fraud rate for a range of data
Function FRAUDRATE(classRange As Range) As Double
    Dim fraudCount As Long
    Dim totalCount As Long
    Dim cell As Range
    
    fraudCount = 0
    totalCount = 0
    
    For Each cell In classRange
        If Not IsEmpty(cell) Then
            If cell.Value = 1 Then
                fraudCount = fraudCount + 1
            End If
            totalCount = totalCount + 1
        End If
    Next cell
    
    If totalCount > 0 Then
        FRAUDRATE = fraudCount / totalCount
    Else
        FRAUDRATE = 0
    End If
End Function

' Calculate F1 score given precision and recall
Function F1SCORE(precision As Double, recall As Double) As Double
    If precision + recall > 0 Then
        F1SCORE = 2 * (precision * recall) / (precision + recall)
    Else
        F1SCORE = 0
    End If
End Function

' Calculate model precision
Function PRECISION(actualClassRange As Range, predictedClassRange As Range) As Double
    If actualClassRange.Count <> predictedClassRange.Count Then
        PRECISION = CVErr(xlErrValue)
        Exit Function
    End If
    
    Dim truePositives As Long, falsePositives As Long
    Dim i As Long
    
    truePositives = 0
    falsePositives = 0
    
    For i = 1 To actualClassRange.Count
        If Not IsEmpty(actualClassRange(i)) And Not IsEmpty(predictedClassRange(i)) Then
            If predictedClassRange(i).Value = 1 Then
                If actualClassRange(i).Value = 1 Then
                    truePositives = truePositives + 1
                Else
                    falsePositives = falsePositives + 1
                End If
            End If
        End If
    Next i
    
    If truePositives + falsePositives > 0 Then
        PRECISION = truePositives / (truePositives + falsePositives)
    Else
        PRECISION = 0
    End If
End Function

' Calculate model recall
Function RECALL(actualClassRange As Range, predictedClassRange As Range) As Double
    If actualClassRange.Count <> predictedClassRange.Count Then
        RECALL = CVErr(xlErrValue)
        Exit Function
    End If
    
    Dim truePositives As Long, falseNegatives As Long
    Dim i As Long
    
    truePositives = 0
    falseNegatives = 0
    
    For i = 1 To actualClassRange.Count
        If Not IsEmpty(actualClassRange(i)) And Not IsEmpty(predictedClassRange(i)) Then
            If actualClassRange(i).Value = 1 Then
                If predictedClassRange(i).Value = 1 Then
                    truePositives = truePositives + 1
                Else
                    falseNegatives = falseNegatives + 1
                End If
            End If
        End If
    Next i
    
    If truePositives + falseNegatives > 0 Then
        RECALL = truePositives / (truePositives + falseNegatives)
    Else
        RECALL = 0
    End If
End Function

' Calculate model accuracy
Function ACCURACY(actualClassRange As Range, predictedClassRange As Range) As Double
    If actualClassRange.Count <> predictedClassRange.Count Then
        ACCURACY = CVErr(xlErrValue)
        Exit Function
    End If
    
    Dim correctPredictions As Long
    Dim totalPredictions As Long
    Dim i As Long
    
    correctPredictions = 0
    totalPredictions = 0
    
    For i = 1 To actualClassRange.Count
        If Not IsEmpty(actualClassRange(i)) And Not IsEmpty(predictedClassRange(i)) Then
            If actualClassRange(i).Value = predictedClassRange(i).Value Then
                correctPredictions = correctPredictions + 1
            End If
            totalPredictions = totalPredictions + 1
        End If
    Next i
    
    If totalPredictions > 0 Then
        ACCURACY = correctPredictions / totalPredictions
    Else
        ACCURACY = 0
    End If
End Function

' Assign risk category based on fraud probability
Function RISKCATEGORY(fraudProbability As Double) As String
    If fraudProbability >= 0.7 Then
        RISKCATEGORY = "High Risk"
    ElseIf fraudProbability >= 0.3 Then
        RISKCATEGORY = "Medium Risk"
    Else
        RISKCATEGORY = "Low Risk"
    End If
End Function

' Calculate the cost of a fraud prediction model
Function FRAUDCOST(actualClassRange As Range, predictedClassRange As Range, _
                  transactionAmountRange As Range, _
                  costPerFalsePositive As Double, _
                  costMultiplierFalseNegative As Double) As Double
    ' Validate input ranges
    If actualClassRange.Count <> predictedClassRange.Count Or _
       actualClassRange.Count <> transactionAmountRange.Count Then
        FRAUDCOST = CVErr(xlErrValue)
        Exit Function
    End If
    
    Dim falsePositiveCost As Double
    Dim falseNegativeCost As Double
    Dim i As Long
    
    falsePositiveCost = 0
    falseNegativeCost = 0
    
    For i = 1 To actualClassRange.Count
        If Not IsEmpty(actualClassRange(i)) And Not IsEmpty(predictedClassRange(i)) And Not IsEmpty(transactionAmountRange(i)) Then
            ' False positive cost - fixed cost per incident
            If actualClassRange(i).Value = 0 And predictedClassRange(i).Value = 1 Then
                falsePositiveCost = falsePositiveCost + costPerFalsePositive
            End If
            
            ' False negative cost - proportional to transaction amount
            If actualClassRange(i).Value = 1 And predictedClassRange(i).Value = 0 Then
                falseNegativeCost = falseNegativeCost + (transactionAmountRange(i).Value * costMultiplierFalseNegative)
            End If
        End If
    Next i
    
    FRAUDCOST = falsePositiveCost + falseNegativeCost
End Function

' Calculate optimal threshold for fraud detection based on cost
Function OPTIMALTHRESHOLD(actualClassRange As Range, fraudProbabilityRange As Range, _
                         transactionAmountRange As Range, _
                         costPerFalsePositive As Double, _
                         costMultiplierFalseNegative As Double) As Double
    ' Validate input ranges
    If actualClassRange.Count <> fraudProbabilityRange.Count Or _
       actualClassRange.Count <> transactionAmountRange.Count Then
        OPTIMALTHRESHOLD = CVErr(xlErrValue)
        Exit Function
    End If
    
    Dim thresholds(9) As Double
    Dim costs(9) As Double
    Dim bestThreshold As Double
    Dim minCost As Double
    Dim i As Long, j As Long
    
    ' Try different thresholds
    For i = 0 To 9
        thresholds(i) = (i + 1) / 20  ' 0.05 to 0.5 in 0.05 increments
        costs(i) = 0
        
        ' Calculate cost for this threshold
        For j = 1 To actualClassRange.Count
            If Not IsEmpty(actualClassRange(j)) And Not IsEmpty(fraudProbabilityRange(j)) And Not IsEmpty(transactionAmountRange(j)) Then
                ' Determine prediction based on threshold
                Dim predicted As Integer
                If fraudProbabilityRange(j).Value >= thresholds(i) Then
                    predicted = 1
                Else
                    predicted = 0
                End If
                
                ' Calculate costs
                If actualClassRange(j).Value = 0 And predicted = 1 Then
                    ' False positive cost
                    costs(i) = costs(i) + costPerFalsePositive
                ElseIf actualClassRange(j).Value = 1 And predicted = 0 Then
                    ' False negative cost
                    costs(i) = costs(i) + (transactionAmountRange(j).Value * costMultiplierFalseNegative)
                End If
            End If
        Next j
    Next i
    
    ' Find threshold with minimum cost
    minCost = costs(0)
    bestThreshold = thresholds(0)
    
    For i = 1 To 9
        If costs(i) < minCost Then
            minCost = costs(i)
            bestThreshold = thresholds(i)
        End If
    Next i
    
    OPTIMALTHRESHOLD = bestThreshold
End Function