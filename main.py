# main.py (excerpt)
from core import sensors, persistence, control, stage, safety, ble_gatt

def loop():
    while True:
        r = sensors.read_all()                            # t, rh, co2, lx
        t, rh, co2, lx = sensors.select_best(r)
        thr = control.get_active_thresholds()
        fan  = (co2 > thr.co2_max) or (t > thr.temp_max)
        mist = (rh < thr.rh_min)
        light= control.light_window_now() and control.confirm_lux(lx)

        fan  = control.hyst("fan", fan)
        mist = control.hyst("mist", mist)
        light= control.hyst("light", light)

        control.set_relays(fan=fan, mist=mist, light=light)
        persistence.log_reading_and_actions(...)
        if stage.mode() in ("FULL","SEMI") and stage.ready():
            stage.advance_or_flag()

        ble_gatt.notify_env_packet(t, rh, co2, lx)
        safety.kick_watchdog()
        control.sleep_tick()
