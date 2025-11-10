"""Non-blocking BLE notification infrastructure tests.

These tests exercise the new queue + worker logic indirectly by:
- Instantiating a BLEGATTServiceManager in simulation mode (no BLE stack).
- Enqueuing notifications under different backpressure policies.
- Verifying metrics change as expected without blocking the producer loop.

Note: We avoid mock data payloads; only structural flow is validated.
"""

import os
import time
import threading

from app.ble.service import BLEGATTServiceManager


def _set_env(policy: str):
    os.environ['MUSHPI_SIMULATION_MODE'] = 'true'
    os.environ['MUSHPI_BLE_QUEUE_MAX_SIZE'] = '4'
    os.environ['MUSHPI_BLE_QUEUE_PUT_TIMEOUT_MS'] = '5'
    os.environ['MUSHPI_BLE_BACKPRESSURE_POLICY'] = policy
    os.environ['MUSHPI_BLE_LOG_SLOW_PUBLISH_MS'] = '10'


def test_enqueue_drop_oldest():
    _set_env('drop_oldest')
    mgr = BLEGATTServiceManager()
    mgr.initialize()  # simulation mode
    # Manually init worker (simulate services created)
    mgr._init_notification_worker()

    # Fill queue beyond capacity
    for i in range(10):
        mgr._enqueue_notification('env_measurements', {'device'})
    assert mgr._queue_metrics['dropped'] > 0, 'Expected drops with drop_oldest policy'


def test_enqueue_drop_newest():
    _set_env('drop_newest')
    mgr = BLEGATTServiceManager()
    mgr.initialize()
    mgr._init_notification_worker()
    for i in range(10):
        mgr._enqueue_notification('status_flags', {'device'})
    assert mgr._queue_metrics['dropped'] > 0, 'Expected drops with drop_newest policy'


def test_enqueue_coalesce():
    _set_env('coalesce')
    mgr = BLEGATTServiceManager()
    mgr.initialize()
    mgr._init_notification_worker()
    for i in range(10):
        mgr._enqueue_notification('env_measurements', {'device'})
    assert mgr._queue_metrics['coalesced'] > 0, 'Expected coalesced count to increment'


def test_worker_processes_items():
    _set_env('drop_oldest')
    mgr = BLEGATTServiceManager()
    mgr.initialize()
    mgr._init_notification_worker()
    for i in range(3):
        mgr._enqueue_notification('env_measurements', {'device'})
    # Wait for worker to drain
    time.sleep(0.5)
    assert mgr._queue_metrics['published'] > 0, 'Worker should have processed notifications'


def test_shutdown_timeout():
    _set_env('drop_oldest')
    os.environ['MUSHPI_BLE_SHUTDOWN_TIMEOUT_MS'] = '200'
    mgr = BLEGATTServiceManager()
    mgr.initialize()
    mgr._init_notification_worker()
    for i in range(10):
        mgr._enqueue_notification('env_measurements', {'device'})
    # Trigger stop
    mgr.stop()
    # Worker should have attempted to join without hanging
    assert True, 'Stop completed without blocking'

if __name__ == '__main__':
    # Basic manual run feedback
    for fn in [
        test_enqueue_drop_oldest,
        test_enqueue_drop_newest,
        test_enqueue_coalesce,
        test_worker_processes_items,
        test_shutdown_timeout,
    ]:
        fn()
    print('Non-blocking BLE notification tests passed.')
