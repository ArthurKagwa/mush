"""
BLE UART (Nordic UART Service) Characteristics
"""
import logging
from ..base import BaseCharacteristic
from ..uuids import UART_RX_CHAR_UUID, UART_TX_CHAR_UUID

logger = logging.getLogger(__name__)

class UARTRXCharacteristic(BaseCharacteristic):
    """
    UART RX Characteristic (Client to Server)
    - Write-only from the client's perspective.
    """
    def __init__(self, service, simulation_mode=False):
        super().__init__(UART_RX_CHAR_UUID, ["write", "write-without-response"], service, simulation_mode)
        self.write_callback = None

    def _handle_read(self, options: dict) -> bytes:
        # This characteristic is write-only, so read should return empty
        logger.debug("UART RX read attempted (write-only characteristic)")
        return b''

    def _handle_write(self, value: bytes, options: dict):
        if self.write_callback:
            try:
                self.write_callback(value)
            except Exception as e:
                logger.error(f"Error in UART RX write callback: {e}")
        else:
            logger.warning("UART RX write received but no callback is set.")

    def set_write_callback(self, callback):
        self.write_callback = callback

class UARTTXCharacteristic(BaseCharacteristic):
    """
    UART TX Characteristic (Server to Client)
    - Notify-only from the client's perspective.
    """
    def __init__(self, service, simulation_mode=False):
        super().__init__(UART_TX_CHAR_UUID, ["read", "notify"], service, simulation_mode)

    def send(self, data: bytes):
        """Send data to the client via notification."""
        logger.info(f"UART TX sending {len(data)} bytes")
        self.notify(data)

    def _handle_read(self, options: dict) -> bytes:
        # This characteristic is notify-only, but a read request should return empty.
        return b''
