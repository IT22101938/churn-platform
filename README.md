# Customer Churn Prediction & Analysis Platform

An end-to-end machine learning project that takes the Telco Customer Churn
dataset from raw CSV all the way to a deployed, explainable prediction pipeline
— combining SQL analysis, statistical experimentation, classical ML, deep
learning, experiment tracking, and a GenAI explanation layer.

---

## Key Findings

**SQL Analysis:**
Month-to-month contract customers churn at 42.7% — 15x higher than two-year
contract customers (2.8%). New customers in their first 6 months are the
highest-risk segment at 52.9% churn rate, dropping steadily to 9.5% for
customers with 49+ months tenure.

**Statistical Testing:**
A simulated A/B test on 3,875 high-risk customers found a retention offer
reduced churn by 9.6 percentage points (chi-square=38.06, p≈0,
95% CI [6.6%, 12.6%]). Randomization was confirmed via balance check (p=0.14).

**Modeling:**
Among three models trained on the same 80/20 stratified split:

| Model | Accuracy | Precision | Recall | F1 | AUC |
|---|---|---|---|---|---|
| XGBoost | 0.803 | 0.660 | 0.535 | 0.591 | **0.844** |
| Random Forest | 0.760 | 0.533 | 0.783 | 0.634 | 0.844 |
| PyTorch NN | 0.791 | 0.629 | 0.521 | 0.570 | 0.837 |

XGBoost (max_depth=3) achieved the best AUC of 0.844, outperforming both
Random Forest and a from-scratch PyTorch neural network. MLflow tracking
across 5 runs confirmed shallower XGBoost configurations generalized better
— consistent with the well-documented tendency of gradient-boosted trees to
outperform deep learning on small, structured tabular datasets. This result
is reported honestly rather than tuned to make the neural network win.

**GenAI Layer:**
A RAG pipeline combined churn predictions with sentence-transformer embeddings
and GPT-2 text generation to produce plain-English risk explanations for the
top at-risk customers (highest predicted churn probability: 95.5%).

---

## Project Structure

```
churn-platform/
├── data/
│   ├── raw/               ← original Kaggle CSV (not committed)
│   └── processed/         ← churn_clean.csv + churn.db
├── sql/                   ← 20 analytical SQL queries across 4 files
├── notebooks/
│   ├── 01_sql_setup.ipynb         ← load CSV → SQLite, run queries
│   ├── 02_eda.ipynb               ← distributions, correlations, EDA
│   ├── 03_statistical_testing.ipynb  ← A/B test simulation + hypothesis tests
│   ├── 04_modeling.ipynb          ← XGBoost + Random Forest + PyTorch NN
│   ├── 05_mlflow_tracking.ipynb   ← experiment tracking across 5 runs
│   └── 06_rag_explanations.ipynb  ← RAG pipeline + LLM explanations
├── api/                   ← FastAPI serving app
├── docker/                ← Dockerfile
├── reports/               ← CV bullets, output reports
└── requirements.txt
```

---

## The Story, Step by Step

| Step | What I did | Skill it proves |
|---|---|---|
| 1. SQL | Loaded raw CSV into SQLite, wrote 20 analytical queries (window functions, CTEs, subqueries, cohort analysis) | Real SQL fluency beyond pandas filtering |
| 2. EDA | Distributions, correlation heatmaps, missing-value handling, categorical breakdowns | Independent dataset exploration |
| 3. Statistics | Simulated a retention-offer A/B test; chi-square test, t-test, confidence intervals | Inferential statistics and experimentation |
| 4. Modeling | XGBoost + Random Forest baselines and a PyTorch neural net written from scratch | Deep learning depth + honest model comparison |
| 5. Tracking | Logged 5 runs with MLflow — params, metrics, model artifacts | Experiment tracking as a real ML team does it |
| 6. Deployment | FastAPI endpoint + Docker container | Can ship a model, not just train one |
| 7. GenAI layer | RAG pipeline over synthetic support tickets + LLM explanations | Combines classical ML with generative AI |

---

## How to Run

**Notebooks (Google Colab — free GPU):**
Run notebooks in order 01 → 06. Each notebook mounts Google Drive
at the top — your files persist across sessions.

**Requirements:** upload `WA_Fn-UseC_-Telco-Customer-Churn.csv` from
[Kaggle](https://www.kaggle.com/datasets/blastchar/telco-customer-churn)
into `data/raw/` before running notebook 01.

**API (local machine required):**
```bash
cd api
pip install -r requirements.txt
uvicorn main:app --reload
```
Open http://127.0.0.1:8000/docs for the interactive Swagger UI.

**Docker:**
```bash
docker build -t churn-api -f docker/Dockerfile .
docker run -p 8000:8000 churn-api
```

---

## Honest Notes

- The A/B test intervention is **simulated** — no real retention offer was
  tested. The section demonstrates statistical methodology correctly, not
  a real causal discovery about Telco customers.
- Support tickets in the RAG pipeline are **synthetically generated** from
  structured features as a stand-in for real unstructured text. The RAG
  pipeline architecture is fully real; only the input text is simulated.
- The neural network intentionally uses a simple architecture suited to
  this dataset size (~7,000 rows). Reporting that XGBoost outperformed it
  is the correct and expected finding for small tabular data.

---

## Stack

Python · SQLite · Pandas · Seaborn · SciPy · XGBoost · scikit-learn ·
PyTorch · MLflow · FastAPI · Docker · sentence-transformers · GPT-2
