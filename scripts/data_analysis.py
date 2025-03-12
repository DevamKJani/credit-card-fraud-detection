"""
Exploratory data analysis for the credit card fraud detection dataset.
Generates key visualizations and statistics.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import os
import logging
from datetime import datetime
from config import *

# Set up logging
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def load_cleaned_data():
    """Load the cleaned credit card transaction data."""
    try:
        logging.info(f"Loading cleaned data from {CLEANED_DATA_FILE}")
        df = pd.read_csv(CLEANED_DATA_FILE)
        logging.info(f"Loaded data with shape: {df.shape}")
        return df
    except Exception as e:
        logging.error(f"Error loading cleaned data: {e}")
        raise

def create_visualization_dir():
    """Create directory for visualizations if it doesn't exist."""
    viz_dir = os.path.join(ROOT_DIR, 'visualizations')
    os.makedirs(viz_dir, exist_ok=True)
    return viz_dir

def analyze_class_distribution(df, viz_dir):
    """Analyze and visualize class distribution."""
    logging.info("Analyzing class distribution...")
    
    # Get class counts
    class_counts = df[TARGET].value_counts()
    
    # Create a pie chart
    plt.figure(figsize=(10, 6))
    plt.pie(class_counts, labels=['Legitimate', 'Fraudulent'], 
            autopct='%1.2f%%', startangle=90, colors=['#66b3ff', '#ff9999'])
    plt.title('Transaction Class Distribution')
    plt.axis('equal')
    plt.tight_layout()
    plt.savefig(os.path.join(viz_dir, 'class_distribution_pie.png'))
    plt.close()
    
    # Create a bar chart
    plt.figure(figsize=(10, 6))
    sns.countplot(x=TARGET, data=df, palette=['#66b3ff', '#ff9999'])
    plt.title('Transaction Class Distribution')
    plt.xlabel('Class (0=Legitimate, 1=Fraudulent)')
    plt.ylabel('Count')
    plt.yscale('log')
    plt.tight_layout()
    plt.savefig(os.path.join(viz_dir, 'class_distribution_bar.png'))
    plt.close()
    
    # Log statistics
    fraud_ratio = class_counts[1] / class_counts[0]
    logging.info(f"Class distribution - Legitimate: {class_counts[0]}, Fraud: {class_counts[1]}")
    logging.info(f"Fraud ratio: {fraud_ratio:.6f}")
    
    return {
        'legitimate_count': int(class_counts[0]),
        'fraud_count': int(class_counts[1]),
        'fraud_ratio': fraud_ratio
    }

def analyze_transaction_amounts(df, viz_dir):
    """Analyze and visualize transaction amounts."""
    logging.info("Analyzing transaction amounts...")
    
    # Create a histogram of transaction amounts
    plt.figure(figsize=(12, 6))
    
    # Create two separate histograms for legitimate and fraudulent transactions
    plt.subplot(1, 2, 1)
    sns.histplot(df[df[TARGET] == 0]['Amount'], bins=50, color='#66b3ff')
    plt.title('Amount Distribution - Legitimate Transactions')
    plt.xlabel('Amount')
    plt.ylabel('Count')
    plt.xscale('log')
    
    plt.subplot(1, 2, 2)
    sns.histplot(df[df[TARGET] == 1]['Amount'], bins=50, color='#ff9999')
    plt.title('Amount Distribution - Fraudulent Transactions')
    plt.xlabel('Amount')
    plt.ylabel('Count')
    plt.xscale('log')
    
    plt.tight_layout()
    plt.savefig(os.path.join(viz_dir, 'amount_distribution.png'))
    plt.close()
    
    # Create a boxplot to compare amounts
    plt.figure(figsize=(10, 6))
    sns.boxplot(x=TARGET, y='Amount', data=df, palette=['#66b3ff', '#ff9999'])
    plt.title('Transaction Amount by Class')
    plt.xlabel('Class (0=Legitimate, 1=Fraudulent)')
    plt.ylabel('Amount')
    plt.yscale('log')
    plt.tight_layout()
    plt.savefig(os.path.join(viz_dir, 'amount_boxplot.png'))
    plt.close()
    
    # Log statistics
    amount_stats = df.groupby(TARGET)['Amount'].agg(['mean', 'median', 'min', 'max'])
    logging.info(f"Amount statistics by class:\n{amount_stats}")
    
    return {
        'legitimate_mean': float(amount_stats.loc[0, 'mean']),
        'legitimate_median': float(amount_stats.loc[0, 'median']),
        'fraud_mean': float(amount_stats.loc[1, 'mean']),
        'fraud_median': float(amount_stats.loc[1, 'median'])
    }

def analyze_time_patterns(df, viz_dir):
    """Analyze and visualize transaction time patterns."""
    logging.info("Analyzing time patterns...")
    
    # Convert time back to hours
    df['Hour'] = (df['Time'] * 24) % 24
    
    # Create a histogram of transactions by hour
    plt.figure(figsize=(12, 6))
    
    plt.subplot(1, 2, 1)
    sns.histplot(df[df[TARGET] == 0]['Hour'], bins=24, color='#66b3ff')
    plt.title('Transaction Hour - Legitimate')
    plt.xlabel('Hour of Day')
    plt.ylabel('Count')
    
    plt.subplot(1, 2, 2)
    sns.histplot(df[df[TARGET] == 1]['Hour'], bins=24, color='#ff9999')
    plt.title('Transaction Hour - Fraudulent')
    plt.xlabel('Hour of Day')
    plt.ylabel('Count')
    
    plt.tight_layout()
    plt.savefig(os.path.join(viz_dir, 'transaction_hour.png'))
    plt.close()
    
    # Create a line plot of fraud rate by hour
    hourly_counts = df.groupby(['Hour', TARGET]).size().unstack(fill_value=0)
    hourly_counts['fraud_rate'] = hourly_counts[1] / (hourly_counts[0] + hourly_counts[1])
    
    plt.figure(figsize=(12, 6))
    sns.lineplot(x=hourly_counts.index, y=hourly_counts['fraud_rate'], marker='o')
    plt.title('Fraud Rate by Hour of Day')
    plt.xlabel('Hour of Day')
    plt.ylabel('Fraud Rate')
    plt.grid(True, linestyle='--', alpha=0.7)
    plt.tight_layout()
    plt.savefig(os.path.join(viz_dir, 'fraud_rate_by_hour.png'))
    plt.close()
    
    # Log statistics
    highest_fraud_hour = hourly_counts['fraud_rate'].idxmax()
    lowest_fraud_hour = hourly_counts['fraud_rate'].idxmin()
    logging.info(f"Hour with highest fraud rate: {highest_fraud_hour}")
    logging.info(f"Hour with lowest fraud rate: {lowest_fraud_hour}")
    
    return {
        'highest_fraud_hour': int(highest_fraud_hour),
        'lowest_fraud_hour': int(lowest_fraud_hour)
    }

def analyze_feature_importance(df, viz_dir):
    """Analyze feature importance for fraud detection."""
    logging.info("Analyzing feature importance...")
    
    # Calculate correlation with target
    corr_with_target = df.drop(columns=['Class']).corrwith(df['Class']).sort_values(ascending=False)
    
    # Plot top correlations
    plt.figure(figsize=(12, 8))
    sns.barplot(x=corr_with_target.head(15).values, y=corr_with_target.head(15).index)
    plt.title('Top 15 Features Correlated with Fraud')
    plt.xlabel('Correlation Coefficient')
    plt.tight_layout()
    plt.savefig(os.path.join(viz_dir, 'feature_correlation.png'))
    plt.close()
    
    # Calculate correlation matrix for V features
    v_cols = [col for col in df.columns if col.startswith('V')]
    v_corr = df[v_cols].corr()
    
    # Plot correlation matrix
    plt.figure(figsize=(18, 16))
    mask = np.triu(np.ones_like(v_corr, dtype=bool))
    cmap = sns.diverging_palette(220, 10, as_cmap=True)
    sns.heatmap(v_corr, mask=mask, cmap=cmap, vmax=.3, center=0,
                square=True, linewidths=.5, cbar_kws={"shrink": .5})
    plt.title('Correlation Matrix of V Features')
    plt.tight_layout()
    plt.savefig(os.path.join(viz_dir, 'v_correlation_matrix.png'))
    plt.close()
    
    # Log top features
    logging.info(f"Top 5 features correlated with fraud: {', '.join(corr_with_target.head(5).index)}")
    
    return {
        'top_features': list(corr_with_target.head(5).index)
    }

def export_analysis_summary(metrics, viz_dir):
    """Export a summary of the analysis in CSV format."""
    summary_data = {
        'Metric': [],
        'Value': []
    }
    
    # Flatten the metrics dictionary
    for category, category_metrics in metrics.items():
        for metric_name, metric_value in category_metrics.items():
            summary_data['Metric'].append(f"{category}_{metric_name}")
            summary_data['Value'].append(metric_value)
    
    # Create DataFrame and export
    summary_df = pd.DataFrame(summary_data)
    summary_file = os.path.join(viz_dir, 'analysis_summary.csv')
    summary_df.to_csv(summary_file, index=False)
    logging.info(f"Analysis summary exported to {summary_file}")
    
    return summary_file

def main():
    """Main function to execute the data analysis pipeline."""
    start_time = datetime.now()
    logging.info(f"Data analysis process started at {start_time}")
    
    try:
        # Load cleaned data
        df = load_cleaned_data()
        
        # Create visualization directory
        viz_dir = create_visualization_dir()
        
        # Analyze data
        class_metrics = analyze_class_distribution(df, viz_dir)
        amount_metrics = analyze_transaction_amounts(df, viz_dir)
        time_metrics = analyze_time_patterns(df, viz_dir)
        feature_metrics = analyze_feature_importance(df, viz_dir)
        
        # Export analysis summary
        metrics = {
            'class': class_metrics,
            'amount': amount_metrics,
            'time': time_metrics,
            'feature': feature_metrics
        }
        summary_file = export_analysis_summary(metrics, viz_dir)
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        logging.info(f"Data analysis completed successfully in {duration:.2f} seconds")
        print(f"Data analysis completed successfully. Visualizations saved to {viz_dir}")
        
    except Exception as e:
        logging.error(f"Error in data analysis pipeline: {e}")
        print(f"Error in data analysis pipeline: {e}")

if __name__ == "__main__":
    main()