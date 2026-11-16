# Predicting delivery time for health commodity orders

**Mission and problem:** My mission is to improve access to essential medicines and health supplies in Rwanda and across Africa. Clinics run out of stock when medical stores reorder too late because they don't know how long a donor-funded order will take to arrive. This project predicts the order cycle time (days from placing an order to delivery) so planners can reorder in time.

## Dataset

**USAID GHSC-PSM Health Commodity Delivery Dataset**, published by USAID. It has one row per order line delivered by the Global Health Supply Chain Program (Procurement and Supply Management) from 2016 to 2024: 43,396 rows, 104 columns, 96 countries, with categorical columns (country, transport mode, product category, incoterms...) and numeric ones (quantity, price, estimated lead time...). The target is `Order Cycle Time` in days. After cleaning I use 31,410 rows and 12 input features.

- Source page: https://data.usaid.gov/Health/USAID-GHSC-PSM-Health-Commodity-Delivery-Dataset/tikn-bfy4
- data.usaid.gov went offline in 2025, so I use the archived copy of the official CSV: https://web.archive.org/web/20250129194228/https://data.usaid.gov/api/views/tikn-bfy4/rows.csv?accessType=DOWNLOAD

## API (Swagger UI)

TODO: https://your-service.onrender.com/docs

## Video demo

TODO: YouTube link

## How to run the mobile app

TODO

## Running the notebook

```bash
cd summative
uv sync
uv run jupyter notebook linear_regression/multivariate.ipynb
```

The notebook downloads the dataset the first time it runs and saves the best model to `summative/API/best_model.pkl`.
