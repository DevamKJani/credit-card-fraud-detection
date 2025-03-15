"""
Train and evaluate machine learning models for credit card fraud detection.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import os
import logging
import joblib
from datetime import datetime
from sklearn.model_selection import train_test_split, cross_val_score, StratifiedKFold
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.metrics import classification_report, confusion_matrix, roc_curve, roc_auc_score
from imblearn.over_sampling import SMOTE
from imblearn.under_sampling import RandomUnderSampler
from config import *

# Set up logging
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def load_prepared_data():
    """Load the cleaned credit card transaction data."""
    try:
        logging.info(f"Loading cleaned data from {CLEANED_DATA_FILE}")
        df = pd.read_csv(CLEANED_DATA_FILE)
        logging.info(f"Loaded data with shape: {df.shape}")
        return df
    except FileNotFoundError:
        logging.error(f"Cleaned data file not found at {CLEANED_DATA_FILE}")
        logging.info("Trying to load and clean raw data...")
        try:
            from data_cleaning import load_raw_data, preprocess_data
            raw_df = load_raw_data()
            processed_df = preprocess_data(raw_df)
            processed_df.to_csv(CLEANED_DATA_FILE, index=False)
            logging.info(f"Created cleaned data file at {CLEANED_DATA_FILE}")
            return processed_df
        except Exception as e:
            logging.error(f"Error loading and cleaning raw data: {e}")
            raise
    except Exception as e:
        logging.error(f"Error loading cleaned data: {e}")
        raise

def prepare_train_test_split(df):
    """Prepare the data for training by splitting into train and test sets."""
    logging.info("Preparing train-test split...")
    
    # Define features and target
    features = df.drop(columns=['Class'])
    target = df['Class']
    
    # Create train and test sets
    X_train, X_test, y_train, y_test = train_test_split(
        features, target, test_size=TEST_SIZE, random_state=RANDOM_STATE, stratify=target
    )
    
    logging.info(f"Train set shape: {X_train.shape}, Test set shape: {X_test.shape}")
    
    # Save train and test sets
    train_df = pd.concat([X_train, y_train], axis=1)
    test_df = pd.concat([X_test, y_test], axis=1)
    
    train_df.to_csv(TRAIN_DATA_FILE, index=False)
    test_df.to_csv(TEST_DATA_FILE, index=False)
    
    logging.info(f"Saved train data to {TRAIN_DATA_FILE}")
    logging.info(f"Saved test data to {TEST_DATA_FILE}")
    
    return X_train, X_test, y_train, y_test

def preprocess_features(X_train, X_test):
    """Preprocess the features for model training."""
    logging.info("Preprocessing features...")
    
    # Feature selection - keeping only relevant features
    selected_features = [col for col in X_train.columns if col.startswith('V') or 
                        col in ['Amount_Scaled', 'Hour_Sin', 'Hour_Cos', 
                                'V_Sum', 'V_Mean', 'V_Std']]
    
    X_train_selected = X_train[selected_features]
    X_test_selected = X_test[selected_features]
    
    logging.info(f"Selected {len(selected_features)} features for modeling")
    
    return X_train_selected, X_test_selected, selected_features

def handle_imbalanced_data(X_train, y_train):
    """Handle the class imbalance problem using a combination of undersampling and oversampling."""
    logging.info("Handling class imbalance...")
    
    # Calculate current class distribution
    class_counts = pd.Series(y_train).value_counts()
    majority_class_count = class_counts[0]
    minority_class_count = class_counts[1]
    
    logging.info(f"Original class distribution - Majority: {majority_class_count}, Minority: {minority_class_count}")
    
    # Apply random undersampling to majority class
    target_majority_count = int(majority_class_count * UNDERSAMPLING_RATIO)
    undersampler = RandomUnderSampler(sampling_strategy={0: target_majority_count, 1: minority_class_count},
                                      random_state=RANDOM_STATE)
    X_resampled, y_resampled = undersampler.fit_resample(X_train, y_train)
    
    # Apply SMOTE oversampling to increase minority class
    target_minority_count = int(target_majority_count * 0.5)  # Aim for 1:2 ratio
    oversampler = SMOTE(sampling_strategy={0: target_majority_count, 1: target_minority_count},
                        random_state=RANDOM_STATE)
    X_resampled, y_resampled = oversampler.fit_resample(X_resampled, y_resampled)
    
    # Calculate new class distribution
    new_class_counts = pd.Series(y_resampled).value_counts()
    logging.info(f"New class distribution - Majority: {new_class_counts[0]}, Minority: {new_class_counts[1]}")
    
    return X_resampled, y_resampled

def train_models(X_train, y_train, selected_features):
    """Train multiple models for fraud detection."""
    logging.info("Training fraud detection models...")
    
    models = {
        'logistic_regression': LogisticRegression(max_iter=1000, class_weight='balanced', random_state=RANDOM_STATE),
        'random_forest': RandomForestClassifier(n_estimators=100, class_weight='balanced', random_state=RANDOM_STATE),
        'gradient_boosting': GradientBoostingClassifier(n_estimators=100, random_state=RANDOM_STATE)
    }
    
    trained_models = {}
    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=RANDOM_STATE)
    
    # Create directory for model analysis
    model_analysis_dir = os.path.join(ROOT_DIR, 'model_analysis')
    os.makedirs(model_analysis_dir, exist_ok=True)
    
    # Create directory for models
    models_dir = os.path.dirname(MODEL_FILE)
    os.makedirs(models_dir, exist_ok=True)
    
    for name, model in models.items():
        logging.info(f"Training {name}...")
        
        # Perform cross-validation
        cv_scores = cross_val_score(model, X_train, y_train, cv=cv, scoring='roc_auc')
        logging.info(f"{name} CV ROC-AUC: {cv_scores.mean():.4f} ± {cv_scores.std():.4f}")
        
        # Train the model on the full training set
        model.fit(X_train, y_train)
        trained_models[name] = model
        
        # Save individual model
        model_path = os.path.join(models_dir, f"{name}.pkl")
        joblib.dump(model, model_path)
        logging.info(f"Saved {name} model to {model_path}")
        
        # For tree-based models, analyze feature importance
        if hasattr(model, 'feature_importances_'):
            feature_importance = pd.DataFrame({
                'feature': selected_features,
                'importance': model.feature_importances_
            })
            feature_importance = feature_importance.sort_values('importance', ascending=False)
            logging.info(f"Top 5 important features for {name}: {', '.join(feature_importance['feature'].head(5))}")
            
            # Save feature importance
            feature_importance.to_csv(os.path.join(model_analysis_dir, f'{name}_feature_importance.csv'), index=False)
            
            # Plot feature importance
            plt.figure(figsize=(12, 8))
            sns.barplot(x='importance', y='feature', data=feature_importance.head(10))
            plt.title(f'Top 10 Feature Importance - {name}')
            plt.tight_layout()
            plt.savefig(os.path.join(model_analysis_dir, f'{name}_feature_importance.png'))
            plt.close()
    
    return trained_models

def evaluate_models(models, X_test, y_test):
    """Evaluate the trained models on the test set."""
    logging.info("Evaluating models on test set...")
    
    results = {}
    viz_dir = os.path.join(ROOT_DIR, 'model_analysis')
    
    for name, model in models.items():
        logging.info(f"Evaluating {name}...")
        
        # Make predictions
        y_pred = model.predict(X_test)
        y_pred_proba = model.predict_proba(X_test)[:, 1]
        
        # Calculate metrics
        auc_score = roc_auc_score(y_test, y_pred_proba)
        report = classification_report(y_test, y_pred, output_dict=True)
        
        # Log results
        logging.info(f"{name} Test ROC-AUC: {auc_score:.4f}")
        logging.info(f"{name} Classification Report: \n{classification_report(y_test, y_pred)}")
        
        # Create confusion matrix
        cm = confusion_matrix(y_test, y_pred)
        plt.figure(figsize=(8, 6))
        sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', cbar=False,
                    xticklabels=['Normal', 'Fraud'], yticklabels=['Normal', 'Fraud'])
        plt.title(f'Confusion Matrix - {name}')
        plt.ylabel('True Label')
        plt.xlabel('Predicted Label')
        plt.tight_layout()
        plt.savefig(os.path.join(viz_dir, f'{name}_confusion_matrix.png'))
        plt.close()
        
        # Create ROC curve
        fpr, tpr, _ = roc_curve(y_test, y_pred_proba)
        plt.figure(figsize=(8, 6))
        plt.plot(fpr, tpr, label=f'AUC = {auc_score:.4f}')
        plt.plot([0, 1], [0, 1], 'k--')
        plt.xlabel('False Positive Rate')
        plt.ylabel('True Positive Rate')
        plt.title(f'ROC Curve - {name}')
        plt.legend(loc='lower right')
        plt.grid(True, linestyle='--', alpha=0.7)
        plt.tight_layout()
        plt.savefig(os.path.join(viz_dir, f'{name}_roc_curve.png'))
        plt.close()
        
        # Store results
        results[name] = {
            'auc': auc_score,
            'precision': report['1']['precision'],
            'recall': report['1']['recall'],
            'f1': report['1']['f1-score'],
            'confusion_matrix': cm.tolist()
        }
    
    # Export results to CSV
    results_df = pd.DataFrame({
        'Model': list(results.keys()),
        'AUC': [results[model]['auc'] for model in results],
        'Precision': [results[model]['precision'] for model in results],
        'Recall': [results[model]['recall'] for model in results],
        'F1 Score': [results[model]['f1'] for model in results]
    })
    
    results_file = os.path.join(viz_dir, 'model_comparison.csv')
    results_df.to_csv(results_file, index=False)
    logging.info(f"Model comparison results exported to {results_file}")
    
    # Find best model based on AUC
    best_model_name = results_df.loc[results_df['AUC'].idxmax(), 'Model']
    best_model = models[best_model_name]
    
    # Save best model separately
    joblib.dump(best_model, MODEL_FILE)
    logging.info(f"Best model ({best_model_name}) saved to {MODEL_FILE}")
    
    # Create a model info file with metadata
    model_info = {
        'model_name': best_model_name,
        'training_date': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        'metrics': {
            'auc': float(results[best_model_name]['auc']),
            'precision': float(results[best_model_name]['precision']),
            'recall': float(results[best_model_name]['recall']),
            'f1': float(results[best_model_name]['f1'])
        },
        'feature_count': len(X_test.columns)
    }
    
    model_info_df = pd.DataFrame([model_info])
    model_info_file = os.path.join(os.path.dirname(MODEL_FILE), 'model_info.csv')
    model_info_df.to_csv(model_info_file, index=False)
    
    return best_model_name, results

def main():
    """Main function to execute the model training pipeline."""
    start_time = datetime.now()
    logging.info(f"Model training process started at {start_time}")
    
    try:
        # Load prepared data
        df = load_prepared_data()
        
        # Split into train and test sets
        X_train, X_test, y_train, y_test = prepare_train_test_split(df)
        
        # Preprocess features
        X_train_processed, X_test_processed, selected_features = preprocess_features(X_train, X_test)
        
        # Handle class imbalance
        X_train_balanced, y_train_balanced = handle_imbalanced_data(X_train_processed, y_train)
        
        # Train models
        trained_models = train_models(X_train_balanced, y_train_balanced, selected_features)
        
        # Evaluate models
        best_model_name, results = evaluate_models(trained_models, X_test_processed, y_test)
        
        # Export data for SQL and Excel
        export_dir = os.path.join(ROOT_DIR, 'exports')
        os.makedirs(export_dir, exist_ok=True)
        
        # Export predictions from best model for further analysis
        best_model = trained_models[best_model_name]
        test_df = pd.read_csv(TEST_DATA_FILE)
        test_df['predicted_proba'] = best_model.predict_proba(X_test_processed)[:, 1]
        test_df['predicted_class'] = best_model.predict(X_test_processed)
        test_df['is_false_positive'] = ((test_df['predicted_class'] == 1) & (test_df['Class'] == 0)).astype(int)
        test_df['is_false_negative'] = ((test_df['predicted_class'] == 0) & (test_df['Class'] == 1)).astype(int)
        
        # Export full results for SQL
        sql_export_file = os.path.join(export_dir, 'fraud_predictions_for_sql.csv')
        test_df.to_csv(sql_export_file, index=False)
        
        # Export summary for Excel (limit columns for readability)
        excel_columns = ['Time', 'Amount', 'Class', 'predicted_proba', 'predicted_class', 
                         'is_false_positive', 'is_false_negative']
        excel_export_file = os.path.join(export_dir, 'fraud_predictions_for_excel.csv')
        test_df[excel_columns].to_csv(excel_export_file, index=False)
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        logging.info(f"Model training completed successfully in {duration:.2f} seconds")
        logging.info(f"Best model: {best_model_name}")
        print(f"Model training completed successfully.")
        print(f"Best model: {best_model_name} with AUC: {results[best_model_name]['auc']:.4f}")
        print(f"Model saved to {MODEL_FILE}")
        print(f"Exports for SQL and Excel saved to {export_dir}")
        
    except Exception as e:
        logging.error(f"Error in model training pipeline: {e}")
        print(f"Error in model training pipeline: {e}")

if __name__ == "__main__":
    main()