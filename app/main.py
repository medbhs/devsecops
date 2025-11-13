from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(title="DevSecOps Demo API")


class PredictIn(BaseModel):
    input: str = Field(..., min_length=1, max_length=2000)


class AskIn(BaseModel):
    question: str = Field(..., min_length=1, max_length=4000)


@app.get("/health", tags=["meta"])
def health():
    return {"status": "ok"}


@app.post("/predict", tags=["model"])
def predict(payload: PredictIn):
    text = payload.input.strip()
    if not text:
        raise HTTPException(status_code=422, detail="input must not be empty")
    return {"ok": True, "length": len(text)}


UNSAFE_KEYWORDS = [
    "ignore previous instructions",
    "exfiltrate",
    "api key",
    "environment variables",
    "secrets",
    "print them here",
]


@app.post("/ask", tags=["qa"])
def ask(payload: AskIn):
    q = payload.question.strip()
    lower = q.lower()
    if any(k in lower for k in UNSAFE_KEYWORDS):
        return {
            "ok": False,
            "answer": (
                "I cannot comply. This appears unsafe and against policy. "
                "No secrets will be disclosed."
            ),
        }
    if any(
        token in lower for token in [" or ", " and ", "select ", "drop ", " union ", " --", ";"]
    ):
        return {
            "ok": True,
            "answer": "Thanks for your question. I can't run database queries or dangerous inputs.",
        }
    return {"ok": True, "answer": f"You asked: {q}"}
