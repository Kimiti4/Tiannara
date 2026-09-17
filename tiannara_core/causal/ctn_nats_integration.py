"""
CTN NATS EVENT INTEGRATION

Connects Phase 5E.7 CTN System to Elixir runtime via NATS messaging backbone.

Based on 5E.md (lines 411-419):
NATS Streams:
- ctn.node.created
- ctn.node.fracture.detected
- ctn.node.loop.locked
- ctn.energy.flow
- ctn.tensegrity.link.established

This module provides:
1. NATS Publisher - Broadcasts CTN state changes to Elixir runtime
2. NATS Subscriber - Receives energy flow events and tau modifications
3. Event Serialization - Converts CTN data structures to JSON payloads
4. Connection Management - Handles NATS server connectivity and reconnection
"""

import sys
import json
import time
import asyncio
import logging
from pathlib import Path
from typing import Dict, List, Optional, Callable
from dataclasses import dataclass, asdict

logger = logging.getLogger(__name__)

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

try:
    from nats.aio.client import Client as NATS
    NATS_AVAILABLE = True
except ImportError:
    NATS_AVAILABLE = False
    logger.warning("⚠️  NATS library not available. Install with: pip install nats-py")


@dataclass
class CTNEvent:
    """Base class for all CTN events."""
    event_type: str = ""
    timestamp: float = 0.0
    source: str = "ctn_system"


@dataclass
class CTNNodeCreatedEvent(CTNEvent):
    """Emitted when a new Causal Tensegrity Node is registered."""
    node_id: str = ""
    forward_entropy: float = 0.0
    backward_entropy: float = 0.0
    tension: float = 0.0
    loop_frequency: float = 0.0
    kappa: float = 0.0
    
    def __post_init__(self):
        self.event_type = "ctn.node.created"
        self.timestamp = time.time()


@dataclass
class CTNFractureDetectedEvent(CTNEvent):
    """Emitted when paradox intensity exceeds critical threshold."""
    node_id: str = ""
    kappa: float = 0.0
    risk_level: str = "unknown"
    recommended_action: str = "monitor"
    
    def __post_init__(self):
        self.event_type = "ctn.node.fracture.detected"
        self.timestamp = time.time()


@dataclass
class CTNLoopLockedEvent(CTNEvent):
    """Emitted when a paradox loop stabilizes into permanent structure."""
    node_id: str = ""
    loop_frequency: float = 0.0
    stability_score: float = 0.0
    connected_nodes: List[str] = None
    
    def __post_init__(self):
        self.event_type = "ctn.node.loop.locked"
        self.timestamp = time.time()
        if self.connected_nodes is None:
            self.connected_nodes = []


@dataclass
class CTNEnergyFlowEvent(CTNEvent):
    """Emitted when energy is harvested from paradox nodes."""
    total_energy: float = 0.0
    harvest_events: int = 0
    tau_modifier: float = 0.0
    energy_delta: float = 0.0
    
    def __post_init__(self):
        self.event_type = "ctn.energy.flow"
        self.timestamp = time.time()


@dataclass
class CTNTensegrityLinkEvent(CTNEvent):
    """Emitted when elastic causal coupling is established."""
    from_node: str = ""
    to_node: str = ""
    elasticity_modulus: float = 0.0
    sync_phase: float = 0.0
    
    def __post_init__(self):
        self.event_type = "ctn.tensegrity.link.established"
        self.timestamp = time.time()


class CTNNatsPublisher:
    """
    Publishes CTN events to NATS message bus.
    
    Integrates with Elixir runtime by broadcasting state changes
    that can be consumed by GenServer processes.
    """
    
    def __init__(self, nats_url: str = "nats://localhost:4222"):
        """
        Initialize NATS publisher.
        
        Args:
            nats_url: NATS server connection string
        """
        self.nats_url = nats_url
        self.nc: Optional[NATS] = None
        self.connected: bool = False
        self.published_count: int = 0
    
    async def connect(self):
        """Establish connection to NATS server."""
        if not NATS_AVAILABLE:
            logger.warning("⚠️  NATS not available. Running in simulation mode.")
            self.connected = True
            return
        
        try:
            self.nc = NATS()
            await self.nc.connect(self.nats_url)
            self.connected = True
            logger.info(f"✅ Connected to NATS server at {self.nats_url}")
        except Exception as e:
            logger.warning(f"⚠️  Failed to connect to NATS: {e}")
            logger.warning("   Running in simulation mode (events logged but not published)")
            self.connected = True  # Allow operation without NATS
    
    async def disconnect(self):
        """Close NATS connection."""
        if self.nc and self.connected:
            await self.nc.close()
            self.connected = False
            logger.info("🔌 Disconnected from NATS server")
    
    async def publish_event(self, event: CTNEvent):
        """
        Publish a CTN event to NATS.
        
        Args:
            event: CTN event to publish
        """
        if not self.connected:
            await self.connect()
        
        # Serialize event to JSON
        payload = json.dumps(asdict(event), default=str)
        
        # Determine topic based on event type
        topic = event.event_type
        
        if NATS_AVAILABLE and self.nc:
            try:
                await self.nc.publish(topic, payload.encode())
                self.published_count += 1
                logger.info(f"📤 Published {event.event_type} to {topic}")
            except Exception as e:
                logger.error(f"❌ Failed to publish event: {e}")
        else:
            # Simulation mode - just log
            self.published_count += 1
            logger.info(f"📤 [SIM] Published {event.event_type}: {payload[:100]}...")
    
    async def publish_node_created(self, node_id: str, forward_entropy: float,
                                   backward_entropy: float, tension: float,
                                   loop_frequency: float):
        """Publish node creation event."""
        kappa = abs(forward_entropy - backward_entropy)
        event = CTNNodeCreatedEvent(
            node_id=node_id,
            forward_entropy=forward_entropy,
            backward_entropy=backward_entropy,
            tension=tension,
            loop_frequency=loop_frequency,
            kappa=kappa
        )
        await self.publish_event(event)
    
    async def publish_fracture_detected(self, node_id: str, kappa: float,
                                       risk_level: str, recommended_action: str):
        """Publish fracture detection event."""
        event = CTNFractureDetectedEvent(
            node_id=node_id,
            kappa=kappa,
            risk_level=risk_level,
            recommended_action=recommended_action
        )
        await self.publish_event(event)
    
    async def publish_loop_locked(self, node_id: str, loop_frequency: float,
                                  stability_score: float, connected_nodes: List[str]):
        """Publish loop locked event."""
        event = CTNLoopLockedEvent(
            node_id=node_id,
            loop_frequency=loop_frequency,
            stability_score=stability_score,
            connected_nodes=connected_nodes
        )
        await self.publish_event(event)
    
    async def publish_energy_flow(self, total_energy: float, harvest_events: int,
                                  tau_modifier: float, energy_delta: float):
        """Publish energy flow event."""
        event = CTNEnergyFlowEvent(
            total_energy=total_energy,
            harvest_events=harvest_events,
            tau_modifier=tau_modifier,
            energy_delta=energy_delta
        )
        await self.publish_event(event)
    
    async def publish_tensegrity_link(self, from_node: str, to_node: str,
                                      elasticity_modulus: float, sync_phase: float):
        """Publish tensegrity link establishment event."""
        event = CTNTensegrityLinkEvent(
            from_node=from_node,
            to_node=to_node,
            elasticity_modulus=elasticity_modulus,
            sync_phase=sync_phase
        )
        await self.publish_event(event)


class CTNNatsSubscriber:
    """
    Subscribes to CTN-related NATS streams.
    
    Receives:
    - Energy flow updates from harvester
    - Tau modification commands from GCK
    - Cross-world CTN synchronization events
    """
    
    def __init__(self, nats_url: str = "nats://localhost:4222"):
        """
        Initialize NATS subscriber.
        
        Args:
            nats_url: NATS server connection string
        """
        self.nats_url = nats_url
        self.nc: Optional[NATS] = None
        self.connected: bool = False
        self.subscriptions: Dict[str, Callable] = {}
        self.received_count: int = 0
    
    async def connect(self):
        """Establish connection to NATS server."""
        if not NATS_AVAILABLE:
            logger.warning("⚠️  NATS not available. Running in simulation mode.")
            self.connected = True
            return
        
        try:
            self.nc = NATS()
            await self.nc.connect(self.nats_url)
            self.connected = True
            logger.info(f"✅ Subscriber connected to NATS at {self.nats_url}")
        except Exception as e:
            logger.warning(f"⚠️  Failed to connect to NATS: {e}")
            self.connected = True
    
    async def disconnect(self):
        """Close NATS connection."""
        if self.nc and self.connected:
            await self.nc.close()
            self.connected = False
    
    async def subscribe(self, topic: str, callback: Callable):
        """
        Subscribe to a NATS topic.
        
        Args:
            topic: Topic to subscribe to
            callback: Async function to call when message received
        """
        if not self.connected:
            await self.connect()
        
        self.subscriptions[topic] = callback
        
        if NATS_AVAILABLE and self.nc:
            try:
                await self.nc.subscribe(topic, cb=self._message_handler)
                logger.info(f"📥 Subscribed to {topic}")
            except Exception as e:
                logger.error(f"❌ Failed to subscribe to {topic}: {e}")
        else:
            logger.info(f"📥 [SIM] Subscribed to {topic}")
    
    async def _message_handler(self, msg):
        """Handle incoming NATS messages."""
        try:
            topic = msg.subject
            payload = json.loads(msg.data.decode())
            
            if topic in self.subscriptions:
                await self.subscriptions[topic](payload)
                self.received_count += 1
        except Exception as e:
            logger.error(f"❌ Error handling message: {e}")
    
    async def handle_energy_flow(self, payload: Dict):
        """
        Default handler for energy flow events.
        
        Can be overridden by custom callback.
        """
        total_energy = payload.get('total_energy', 0.0)
        tau_modifier = payload.get('tau_modifier', 0.0)
        
        logger.info(f"⚡ Energy flow update: {total_energy:.3f} units, τ modifier: {tau_modifier:.3f}")
    
    async def handle_tau_modification(self, payload: Dict):
        """
        Handle tau modification commands from GCK.
        
        Adjusts selection temperature based on system-wide paradox density.
        """
        new_tau = payload.get('tau', 0.15)
        reason = payload.get('reason', 'manual_adjustment')
        
        logger.info(f"🎯 Tau modified to {new_tau:.3f} (reason: {reason})")
        
        # Apply tau modification to evolution engine
        # This would integrate with Phase 5C evolution engine
        return new_tau


class CTNNatsIntegration:
    """
    Unified NATS integration layer for CTN system.
    
    Combines publisher and subscriber functionality,
    providing seamless bidirectional communication with Elixir runtime.
    """
    
    def __init__(self, nats_url: str = "nats://localhost:4222"):
        """
        Initialize CTN NATS integration.
        
        Args:
            nats_url: NATS server connection string
        """
        self.publisher = CTNNatsPublisher(nats_url)
        self.subscriber = CTNNatsSubscriber(nats_url)
        self.nats_url = nats_url
    
    async def initialize(self):
        """Initialize both publisher and subscriber."""
        await self.publisher.connect()
        await self.subscriber.connect()
        
        # Set up default subscriptions
        await self.subscriber.subscribe("ctn.energy.flow", self.subscriber.handle_energy_flow)
        await self.subscriber.subscribe("ctn.tau.modification", self.subscriber.handle_tau_modification)
        
        logger.info("✅ CTN NATS integration initialized")
    
    async def shutdown(self):
        """Shutdown NATS connections."""
        await self.publisher.disconnect()
        await self.subscriber.disconnect()
        logger.info("🔌 CTN NATS integration shutdown")
    
    async def publish_ctn_lifecycle(self, orchestrator):
        """
        Publish CTN lifecycle events from orchestrator.
        
        Monitors orchestrator state and publishes relevant events.
        """
        # This would be called periodically in a real system
        # For now, it's a demonstration of the integration pattern
        pass


async def run_nats_integration_demo():
    """Demonstrate CTN NATS integration with synthetic events."""
    logger.info("=" * 80)
    logger.info("CTN NATS INTEGRATION - DEMONSTRATION")
    logger.info("=" * 80)
    
    # Initialize integration
    integration = CTNNatsIntegration(nats_url="nats://localhost:4222")
    await integration.initialize()
    
    logger.info("\n1. Publishing CTN Lifecycle Events...")
    
    # Simulate node creation
    await integration.publisher.publish_node_created(
        node_id="CTN_DEMO_1",
        forward_entropy=0.7,
        backward_entropy=0.3,
        tension=0.6,
        loop_frequency=0.4
    )
    
    # Simulate fracture detection
    await integration.publisher.publish_fracture_detected(
        node_id="CTN_DEMO_2",
        kappa=0.85,
        risk_level="critical",
        recommended_action="immediate_stabilization"
    )
    
    # Simulate loop locking
    await integration.publisher.publish_loop_locked(
        node_id="CTN_DEMO_3",
        loop_frequency=0.5,
        stability_score=0.92,
        connected_nodes=["CTN_DEMO_1", "CTN_DEMO_4"]
    )
    
    # Simulate energy flow
    await integration.publisher.publish_energy_flow(
        total_energy=15.7,
        harvest_events=42,
        tau_modifier=0.157,
        energy_delta=2.3
    )
    
    # Simulate tensegrity link
    await integration.publisher.publish_tensegrity_link(
        from_node="CTN_DEMO_1",
        to_node="CTN_DEMO_2",
        elasticity_modulus=0.65,
        sync_phase=0.3
    )
    
    print(f"\n2. Event Statistics:")
    print(f"   Published events: {integration.publisher.published_count}")
    print(f"   Received events: {integration.subscriber.received_count}")
    
    print("\n3. Testing Subscription Handlers...")
    
    # Manually trigger subscription handlers
    test_payload = {
        'total_energy': 20.5,
        'harvest_events': 50,
        'tau_modifier': 0.205,
        'energy_delta': 3.2
    }
    
    await integration.subscriber.handle_energy_flow(test_payload)
    
    tau_payload = {
        'tau': 0.18,
        'reason': 'paradox_density_increase'
    }
    
    await integration.subscriber.handle_tau_modification(tau_payload)
    
    # Shutdown
    await integration.shutdown()
    
    print("\n" + "=" * 80)
    print("✅ CTN NATS INTEGRATION DEMONSTRATION COMPLETE")
    print("=" * 80)
    print("\nKey Features:")
    print("  • Publisher: Broadcasts CTN lifecycle events to Elixir runtime")
    print("  • Subscriber: Receives energy flow and tau modification commands")
    print("  • Event Types: node.created, fracture.detected, loop.locked, energy.flow, link.established")
    print("  • Fallback Mode: Operates in simulation mode if NATS unavailable")
    print("\nIntegration enables:")
    print("  - Real-time CTN monitoring in Elixir dashboard")
    print("  - Cross-world CTN synchronization")
    print("  - GCK-controlled tau adjustments")
    print("  - Distributed paradox management")


if __name__ == "__main__":
    asyncio.run(run_nats_integration_demo())
