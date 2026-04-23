from chunker import chunk_text


def process_document(content: str) -> list[str]:
    return chunk_text(content)
