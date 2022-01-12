#!/usr/bin/env python3

import asyncio
import websockets
import json
import sys
import wave

async def run_test(uri):
    async with websockets.connect(uri) as websocket:

        wf = wave.open(sys.argv[1], "rb")
        await websocket.send('{ "config" : { "sample_rate" : %d } }' % (wf.getframerate()))
        buffer_size = int(wf.getframerate() * 0.2) # 0.2 seconds of audio
        while True:
            data = wf.readframes(buffer_size)

            if len(data) == 0:
                break

            await websocket.send(data)
            tmp = json.loads(await websocket.recv())
            if "text" in tmp: 
                print(tmp.get("text"))

        await websocket.send('{"eof" : 1}')
        tmp = json.loads(await websocket.recv())
        if "text" in tmp:
            print(tmp.get("text"))

asyncio.get_event_loop().run_until_complete(
    run_test('ws://localhost:2700'))