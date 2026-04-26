import os
from datetime import datetime, timezone
from typing import Any

from dotenv import load_dotenv
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from supabase import Client, create_client

from azure_storage import upload_file
from chunker import split_into_chunks
from document_processor import extract_text_from_pdf, extract_text_from_pptx

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "")

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    supabase: Client | None = None
else:
    supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

app = FastAPI(title="StudyTrack Backend")


def _ensure_supabase() -> Client:
    if supabase is None:
        raise HTTPException(status_code=500, detail="Supabase is not configured")
    return supabase


def _normalize_file_type(filename: str) -> str:
    lower = (filename or "").lower()
    if lower.endswith(".pdf"):
        return "pdf"
    if lower.endswith(".pptx"):
        return "pptx"
    raise HTTPException(status_code=400, detail="Only PDF and PPTX files are supported")


@app.post("/process-document")
async def process_document(
    file: UploadFile = File(...),
    topic_id: str = Form(...),
    user_id: str = Form(...),
    is_shared: bool = Form(False),
) -> dict[str, Any]:
    file_type = _normalize_file_type(file.filename or "")
    file_bytes = await file.read()
    if not file_bytes:
        raise HTTPException(status_code=400, detail="Uploaded file is empty")

    storage_url = upload_file(
        file_bytes=file_bytes,
        filename=file.filename or f"upload.{file_type}",
        content_type=file.content_type or "application/octet-stream",
    )

    db = _ensure_supabase()

    created_note = (
        db.table("uploaded_notes")
        .insert(
            {
                "topic_id": topic_id,
                "user_id": user_id,
                "file_name": file.filename,
                "file_url": storage_url,
                "file_type": file_type,
                "is_shared_with_group": is_shared,
                "processing_status": "processing",
            }
        )
        .execute()
    )

    note_rows = created_note.data or []
    if not note_rows:
        raise HTTPException(status_code=500, detail="Failed to create uploaded note")
    note_id = note_rows[0]["id"]

    try:
        if file_type == "pdf":
            text = extract_text_from_pdf(file_bytes)
        else:
            text = extract_text_from_pptx(file_bytes)

        chunks = split_into_chunks(text, chunk_size=500, overlap=50)

        if chunks:
            payload = [
                {
                    "note_id": note_id,
                    "chunk_index": index,
                    "content": chunk,
                    "created_at": datetime.now(timezone.utc).isoformat(),
                }
                for index, chunk in enumerate(chunks)
            ]
            db.table("note_chunks").insert(payload).execute()

        db.table("uploaded_notes").update({"processing_status": "ready"}).eq("id", note_id).execute()

        return {
            "success": True,
            "note_id": note_id,
            "chunks_count": len(chunks),
            "file_url": storage_url,
        }
    except Exception as error:
        db.table("uploaded_notes").update({"processing_status": "failed"}).eq("id", note_id).execute()
        raise HTTPException(status_code=500, detail=f"Document processing failed: {error}")


@app.get("/health")
def health_check() -> dict[str, str]:
    return {
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
