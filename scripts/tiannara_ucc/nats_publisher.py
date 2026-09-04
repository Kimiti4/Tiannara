import asyncio
import json

class UCCPublisher:
    def __init__(self, url="nats://127.0.0.1:4222"):
        self.url = url
        self.nc = None

    async def connect(self):
        from nats.aio.client import Client as NATS
        self.nc = NATS()
        await self.nc.connect(self.url)

    async def publish_institution(self, genome):
        if not self.nc:
            await self.connect()
        await self.nc.publish("ucc.institution.genome", json.dumps(genome).encode())

    async def publish_constitution(self, genome):
        if not self.nc:
            await self.connect()
        await self.nc.publish("ucc.constitution.genome", json.dumps(genome).encode())

    async def close(self):
        if self.nc:
            await self.nc.close()
