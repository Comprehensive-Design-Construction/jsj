import requests
import asyncio
import os
from typing import Optional
from dotenv import load_dotenv

load_dotenv()


async def _fetch_uv_sync() -> Optional[dict]:
    """
    :return: 구: h0
    """
