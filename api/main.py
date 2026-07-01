"""
main.py — FastAPI app serving the trained XGBoost churn model.

WHY FASTAPI: it's the de facto standard for serving ML models in Python —
fast, async-capable, and it auto-generates interactive API docs (Swagger UI)
from your type hints, which is genuinely useful for demoing this to anyone
(including an interviewer) without writing a separate frontend.

WHY THIS MATTERS FOR THE PROJECT: a model sitting in a notebook is not
"deployed." Wrapping it in an API is what makes it usable by literally
anything else — a website, another microservice, a mobile app. This step
proves you can hand off a trained model to the rest of a real system.

HOW TO RUN LOCALLY:
1. Download xgb_model.joblib and feature_columns.joblib from your Drive's
   churn-platform/models/ folder into this api/ folder.
2. pip install -r requirements.txt
3. uvicorn main:app --reload
4. Open http://127.0.0.1:8000/docs to try it interactively.
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
import joblib
import pandas as pd
import os

app = FastAPI(
    title="Churn Prediction API",
    description="Predicts customer churn probability from account/service features.",
    version="1.0.0",
)

MODEL_PATH = os.path.join(os.path.dirname(__file__), "xgb_model.joblib")
FEATURES_PATH = os.path.join(os.path.dirname(__file__), "feature_columns.joblib")

# Load once at startup, not per-request — re-loading a model file on every
# request would be slow and pointless since the model doesn't change.
model = joblib.load(MODEL_PATH)
feature_columns = joblib.load(FEATURES_PATH)


class CustomerFeatures(BaseModel):
    """
    Raw input fields a caller provides. We accept human-readable categorical
    values here (e.g. "Month-to-month") and one-hot encode internally to
    match what the model was trained on — callers shouldn't need to know
    our internal encoding scheme.
    """
    gender: str = Field(..., example="Female")
    SeniorCitizen: int = Field(..., example=0)
    Partner: str = Field(..., example="Yes")
    Dependents: str = Field(..., example="No")
    tenure: int = Field(..., example=12)
    PhoneService: str = Field(..., example="Yes")
    MultipleLines: str = Field(..., example="No")
    InternetService: str = Field(..., example="Fiber optic")
    OnlineSecurity: str = Field(..., example="No")
    OnlineBackup: str = Field(..., example="Yes")
    DeviceProtection: str = Field(..., example="No")
    TechSupport: str = Field(..., example="No")
    StreamingTV: str = Field(..., example="Yes")
    StreamingMovies: str = Field(..., example="No")
    Contract: str = Field(..., example="Month-to-month")
    PaperlessBilling: str = Field(..., example="Yes")
    PaymentMethod: str = Field(..., example="Electronic check")
    MonthlyCharges: float = Field(..., example=70.35)
    TotalCharges: float = Field(..., example=845.5)


class PredictionResponse(BaseModel):
    churn_probability: float
    churn_prediction: int
    risk_tier: str


def preprocess(features: CustomerFeatures) -> pd.DataFrame:
    """
    Converts raw input into the exact one-hot-encoded column layout the
    model was trained on. Any column the model expects but the input
    doesn't produce (because that category wasn't present) gets filled
    with 0 — this is the standard way to keep train/serve feature
    alignment consistent.
    """
    raw_df = pd.DataFrame([features.dict()])
    categorical_cols = raw_df.select_dtypes(include="object").columns.tolist()
    encoded = pd.get_dummies(raw_df, columns=categorical_cols, drop_first=True)

    # Reindex to the exact training-time column order/set; missing
    # columns become 0, extra columns are dropped.
    encoded = encoded.reindex(columns=feature_columns, fill_value=0)
    return encoded


def risk_tier(prob: float) -> str:
    if prob >= 0.7:
        return "high"
    elif prob >= 0.4:
        return "medium"
    return "low"


@app.get("/")
def health_check():
    return {"status": "ok", "message": "Churn prediction API is running."}


@app.post("/predict", response_model=PredictionResponse)
def predict(features: CustomerFeatures):
    try:
        X = preprocess(features)
        prob = float(model.predict_proba(X)[:, 1][0])
        pred = int(prob >= 0.5)
        return PredictionResponse(
            churn_probability=round(prob, 4),
            churn_prediction=pred,
            risk_tier=risk_tier(prob),
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
