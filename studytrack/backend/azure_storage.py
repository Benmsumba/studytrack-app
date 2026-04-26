import os
from uuid import uuid4
from urllib.parse import urlparse

from supabase import create_client


def _settings() -> tuple[str, str, str]:
    url = os.getenv("SUPABASE_URL", "")
    key = os.getenv("SUPABASE_SERVICE_KEY", "")
    bucket = os.getenv("SUPABASE_STORAGE_BUCKET", "studytrack-notes")
    return url, key, bucket


def _get_client():
    supabase_url, supabase_service_key, _ = _settings()
    if not supabase_url or not supabase_service_key:
        raise RuntimeError("Missing SUPABASE_URL or SUPABASE_SERVICE_KEY")
    return create_client(supabase_url, supabase_service_key)


def _extract_path_from_url(value: str) -> str:
    # Expected public URL: /storage/v1/object/public/<bucket>/<path>
    _, _, bucket_name = _settings()
    parsed = urlparse(value or "")
    marker = f"/storage/v1/object/public/{bucket_name}/"
    if marker not in parsed.path:
        return ""
    return parsed.path.split(marker, 1)[1]


def upload_file(file_bytes: bytes, filename: str, content_type: str) -> str:
    client = _get_client()
    _, _, bucket_name = _settings()
    object_path = f"uploads/{uuid4()}_{filename}"

    client.storage.from_(bucket_name).upload(
        object_path,
        file_bytes,
        file_options={"content-type": content_type, "upsert": "true"},
    )

    public_url = client.storage.from_(bucket_name).get_public_url(object_path)
    if isinstance(public_url, dict):
        return public_url.get("publicUrl", "")
    return str(public_url)


def delete_file(blob_name: str) -> bool:
    try:
        client = _get_client()
        _, _, bucket_name = _settings()
        object_path = blob_name

        if blob_name.startswith("http"):
            object_path = _extract_path_from_url(blob_name)

        if not object_path:
            return False

        client.storage.from_(bucket_name).remove([object_path])
        return True
    except Exception:
        return False
