from azure.storage.blob import BlobServiceClient


class AzureStorageService:
    def __init__(self, connection_string: str) -> None:
        self.client = BlobServiceClient.from_connection_string(connection_string)
