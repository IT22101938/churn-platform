# Serving the model (Steps 6-7) — local setup required

Colab can train models, but it can't run a persistent web server you visit
in a browser, and Docker doesn't run inside Colab at all. So Steps 6-7
need a local terminal (your own laptop, or a free environment like
GitHub Codespaces if you don't have one). Everything else in this project
(SQL, EDA, stats, modeling, MLflow) stays in Colab — this is the one
deliberate exception, and it's worth explaining in your README/interview:
**"training happened in Colab for free GPU access; serving happened
locally/in Docker because that's how it would actually be deployed."**

## Step 6: Run the API locally

```bash
# 1. From your Drive, download these two files into the api/ folder:
#    - models/xgb_model.joblib
#    - models/feature_columns.joblib

cd churn-platform/api
pip install -r requirements.txt
uvicorn main:app --reload
```

Open **http://127.0.0.1:8000/docs** — FastAPI auto-generates an interactive
UI where you can fill in a sample customer and hit "Execute" to get a real
prediction back. This is genuinely useful to screen-record or screenshot
for your portfolio.

Test it from the command line instead, if you prefer:
```bash
curl -X POST http://127.0.0.1:8000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "gender": "Female", "SeniorCitizen": 0, "Partner": "Yes", "Dependents": "No",
    "tenure": 5, "PhoneService": "Yes", "MultipleLines": "No",
    "InternetService": "Fiber optic", "OnlineSecurity": "No", "OnlineBackup": "No",
    "DeviceProtection": "No", "TechSupport": "No", "StreamingTV": "Yes",
    "StreamingMovies": "Yes", "Contract": "Month-to-month", "PaperlessBilling": "Yes",
    "PaymentMethod": "Electronic check", "MonthlyCharges": 90.5, "TotalCharges": 452.5
  }'
```

## Step 7: Containerize with Docker

**Why Docker, conceptually:** your API works on your machine because Python,
the right library versions, and the model file all happen to be present.
Docker packages all of that into one portable image, so it runs identically
on any machine (or any cloud provider) — "it works on my machine" stops
being a risk.

```bash
cd churn-platform
docker build -t churn-api -f docker/Dockerfile .
docker run -p 8000:8000 churn-api
```

Visit http://127.0.0.1:8000/docs again — same API, but now running inside
an isolated container instead of directly on your machine.

If you don't have Docker installed, [Docker Desktop](https://www.docker.com/products/docker-desktop/)
is free for personal use.
