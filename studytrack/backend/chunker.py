def chunk_text(content: str, chunk_size: int = 1000) -> list[str]:
    return [content[i : i + chunk_size] for i in range(0, len(content), chunk_size)]
