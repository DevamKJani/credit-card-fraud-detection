"""
Configuration settings for the credit card fraud detection project.
"""

import os
from pathlib import Path

# Define root directory
ROOT_DIR = Path(__file__).parent.parent

# Data paths
DATA_DIR = os.path.join(ROOT_DIR, 'data')
RAW_DATA_DIR = os.path.join(DATA_DIR, 'raw')
PROCESSED_DATA_DIR = os.path.join(DATA_DIR, 'processed')

# File paths
RAW_DATA_FILE = os.path.join(RAW_DATA_DIR, 'creditcard.csv')
CLEANED_DATA_FILE = os.path.join(PROCESSED_DATA_DIR, 'creditcard_cleaned.csv')
TRAIN_DATA_FILE = os.path.join(PROCESSED_DATA_DIR, 'creditcard_train.csv')
TEST_DATA_FILE = os.path.join(PROCESSED_DATA_DIR, 'creditcard_test.csv')
MODEL_FILE = os.path.join(ROOT_DIR, 'models', 'fraud_detection_model.pkl')

# Ensure directories exist
os.makedirs(os.path.join(ROOT_DIR, 'models'), exist_ok=True)
os.makedirs(PROCESSED_DATA_DIR, exist_ok=True)

# Model parameters
TEST_SIZE = 0.2
RANDOM_STATE = 42

# Feature settings
TIME_FEATURES = ['Time']
AMOUNT_FEATURES = ['Amount']
V_FEATURES = [f'V{i}' for i in range(1, 29)]
TARGET = 'Class'

# Sampling parameters for handling imbalanced data
UNDERSAMPLING_RATIO = 0.5  # Ratio of majority class to keep
OVERSAMPLING_RATIO = 0.5   # Ratio of minority class to synthesize

# Logging configuration
LOG_DIR = os.path.join(ROOT_DIR, 'logs')
os.makedirs(LOG_DIR, exist_ok=True)
LOG_FILE = os.path.join(LOG_DIR, 'data_processing.log')

# Threshold for fraud detection (can be tuned later)
FRAUD_THRESHOLD = 0.5