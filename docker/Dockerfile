# Dockerfile — packages the FastAPI churn-prediction service into a
# portable image.
#
# WHY python:3.11-slim: full python:3.11 includes a lot of build tools and
# docs we don't need at runtime, making the image needlessly large.
# "slim" keeps the image smaller and faster to build/pull, which matters
# once you're paying for registry storage or deploy time in a real system.

FROM python:3.11-slim

WORKDIR /app

# Copy requirements first and install before copying the rest of the code.
# WHY this order matters: Docker caches each layer. If requirements.txt
# hasn't changed, Docker reuses the cached "pip install" layer instead of
# re-running it every time you change main.py — much faster rebuilds.
COPY api/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY api/main.py .
COPY api/xgb_model.joblib .
COPY api/feature_columns.joblib .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
