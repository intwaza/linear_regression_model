"""
Retraining for my order cycle time model.

The /retrain endpoint in prediction.py uses these functions when someone uploads
a CSV of new orders.
"""

import joblib
import pandas as pd
from sklearn.base import clone

# the columns of my training data (same as in the notebook)
CATEGORICAL = ["country", "order_type", "transport_mode", "product_category", "health_element",
               "vendor_incoterm", "destination_incoterm"]
NUMERIC = ["ordered_quantity", "unit_price", "est_lead_time_days", "order_year", "order_month"]
FEATURES = CATEGORICAL + NUMERIC
TARGET = "order_cycle_days"


def missing_columns(new_rows):
    """The columns the uploaded file should have but doesn't."""
    return [col for col in FEATURES + [TARGET] if col not in new_rows.columns]


def clean_new_rows(new_rows):
    """Cleans the new rows like in the notebook: numbers must be numbers, no empty cells,
    and quantity and cycle time have to be more than 0."""
    new_rows = new_rows[FEATURES + [TARGET]].copy()
    for col in NUMERIC + [TARGET]:
        new_rows[col] = pd.to_numeric(new_rows[col], errors="coerce")
    new_rows = new_rows.dropna()
    new_rows = new_rows[(new_rows[TARGET] > 0) & (new_rows["ordered_quantity"] > 0)]
    new_rows[CATEGORICAL] = new_rows[CATEGORICAL].astype(str)
    return new_rows


def retrain_model(model, training_data, new_rows, model_path, data_path):
    """Fits the model again on the old data plus the new rows, and saves it."""
    combined = pd.concat([training_data, new_rows], ignore_index=True)

    # A random forest cannot keep training on new rows like SGD can with partial_fit.
    # So I make an unfitted copy of the pipeline (same settings) and fit it on old + new data.
    new_model = clone(model)
    new_model.fit(combined[FEATURES], combined[TARGET])

    joblib.dump(new_model, model_path, compress=3)
    combined.to_csv(data_path, index=False)
    return new_model, combined
