#!/usr/bin/env python3
"""Shrinks the piano SoundFont used to play the psalm tones.

The psalm tones only span B2–D5 and their notes are short (a quarter note at
90 is 0.67 s, the longest note a half note). From a one-instrument SF2 bank,
this keeps the zones covering a key range, cuts each sample after a few
seconds with a fade-out (dropping its loop, which starts later), and halves
the sample rate. The lowest and highest kept zones are widened so that every
key still finds a sample.

Usage (from the aelf-flutter root):
    python3 tool/shrink_soundfont.py ../emmasongs_client/assets/sounds/piano.sf2 \
        assets/sounds/piano.sf2

Source bank: FreePats "Upright Piano KW" (small, bright, 2019-07-03), by
Gonzalo and Roberto, CC0 1.0 — http://freepats.zenvoid.org/Piano/
Standard library only.
"""

from __future__ import annotations

import argparse
import math
import struct
import sys
from array import array
from operator import mul
from pathlib import Path

# SF2 generator operators used here.
KEY_RANGE = 43
SAMPLE_MODES = 54
SAMPLE_ID = 53
# Generators that move sample addresses: their offsets would no longer fit.
ADDRESS_OFFSETS = {0, 1, 2, 3, 4, 12, 45, 50}

SHDR_SIZE = 46
SAMPLE_PADDING = 46  # zero frames required after each sample by the spec


class SoundFontError(Exception):
    pass


def _chunks(data: bytes, start: int, end: int):
    while start < end:
        chunk_id = data[start:start + 4]
        length = struct.unpack('<I', data[start + 4:start + 8])[0]
        yield chunk_id, start + 8, length
        start += 8 + length + (length & 1)


def _chunk(chunk_id: bytes, payload: bytes) -> bytes:
    padding = b'\0' if len(payload) & 1 else b''
    return chunk_id + struct.pack('<I', len(payload)) + payload + padding


def _list(list_type: bytes, chunks: list[bytes]) -> bytes:
    return _chunk(b'LIST', list_type + b''.join(chunks))


def read_soundfont(data: bytes) -> dict[bytes, dict[bytes, bytes]]:
    """The sub-chunks of the INFO, sdta and pdta lists, by list type."""
    if data[:4] != b'RIFF' or data[8:12] != b'sfbk':
        raise SoundFontError('not a SoundFont 2 file')
    lists: dict[bytes, dict[bytes, bytes]] = {}
    for chunk_id, start, length in _chunks(data, 12, len(data)):
        if chunk_id != b'LIST':
            continue
        list_type = data[start:start + 4]
        lists[list_type] = {sub_id: data[sub_start:sub_start + sub_length]
                            for sub_id, sub_start, sub_length
                            in _chunks(data, start + 4, start + length)}
    return lists


def _records(payload: bytes, size: int) -> list[bytes]:
    return [payload[i:i + size] for i in range(0, len(payload), size)]


def lowpass_kernel(cutoff: float, taps: int) -> list[float]:
    """Blackman-windowed sinc low-pass filter; cutoff in cycles per input sample."""
    middle = (taps - 1) / 2
    kernel = []
    for n in range(taps):
        x = n - middle
        sinc = 2 * cutoff if x == 0 else math.sin(2 * math.pi * cutoff * x) / (math.pi * x)
        window = (0.42 - 0.5 * math.cos(2 * math.pi * n / (taps - 1))
                  + 0.08 * math.cos(4 * math.pi * n / (taps - 1)))
        kernel.append(sinc * window)
    total = sum(kernel)
    return [k / total for k in kernel]


def halve_rate(frames: list[float], kernel: list[float]) -> list[float]:
    """Low-pass filtering then one frame out of two."""
    half = len(kernel) // 2
    padded = [0.0] * half + frames + [0.0] * half
    return [sum(map(mul, kernel, padded[i:i + len(kernel)]))
            for i in range(0, len(frames), 2)]


def fade_out(frames: list[float], length: int) -> list[float]:
    """Raised-cosine fade over the last [length] frames."""
    length = min(length, len(frames))
    start = len(frames) - length
    for i in range(length):
        frames[start + i] *= 0.5 * (1 + math.cos(math.pi * (i + 1) / length))
    return frames


def shrink(data: bytes, low_key: int, high_key: int, seconds: float,
           fade_seconds: float, halve: bool) -> bytes:
    lists = read_soundfont(data)
    info, sdta, pdta = lists[b'INFO'], lists[b'sdta'], lists[b'pdta']

    instruments = _records(pdta[b'inst'], 22)
    if len(instruments) != 2:  # one instrument + the terminal record
        raise SoundFontError('expected a bank with a single instrument')
    bags = [struct.unpack('<HH', r) for r in _records(pdta[b'ibag'], 4)]
    gens = [struct.unpack('<HH', r) for r in _records(pdta[b'igen'], 4)]
    headers = _records(pdta[b'shdr'], SHDR_SIZE)
    samples = array('h')
    samples.frombytes(sdta[b'smpl'])
    if sys.byteorder == 'big':
        samples.byteswap()

    # Zones of the instrument: a global zone has no sample ID.
    global_gens: list[tuple[int, int]] = []
    zones: list[tuple[int, int, list[tuple[int, int]], int]] = []  # low, high, gens, sample
    for bag, next_bag in zip(bags, bags[1:]):
        zone = gens[bag[0]:next_bag[0]]
        ops = dict(zone)
        if SAMPLE_ID not in ops:
            global_gens = zone
            continue
        if ADDRESS_OFFSETS & ops.keys():
            raise SoundFontError('sample address offsets are not supported')
        key_range = ops.get(KEY_RANGE, 127 << 8)
        low, high = key_range & 0xFF, key_range >> 8
        if high >= low_key and low <= high_key:
            others = [(op, amount) for op, amount in zone
                      if op not in (KEY_RANGE, SAMPLE_MODES, SAMPLE_ID)]
            zones.append((low, high, others, ops[SAMPLE_ID]))
    if not zones:
        raise SoundFontError('no zone in the key range')
    zones.sort()
    zones[0] = (0,) + zones[0][1:]
    zones[-1] = (zones[-1][0], 127) + zones[-1][2:]

    kernel = lowpass_kernel(cutoff=0.2268, taps=63)  # ~10 kHz at 44.1 kHz
    new_samples = array('h')
    new_headers = []
    new_igen: list[tuple[int, int]] = list(global_gens)
    new_ibag: list[tuple[int, int]] = []
    if global_gens:
        new_ibag.append((0, 0))
    for index, (low, high, others, sample_id) in enumerate(zones):
        name = headers[sample_id][:20]
        start, end, _, _, rate, root, correction, _, _ = \
            struct.unpack('<IIIIIBbHH', headers[sample_id][20:])
        frames = [s / 32768 for s in samples[start:min(end, start + round(seconds * rate))]]
        frames = fade_out(frames, round(fade_seconds * rate))
        if halve:
            frames, rate = halve_rate(frames, kernel), rate // 2
        offset = len(new_samples)
        new_samples.extend(max(-32768, min(32767, round(f * 32768))) for f in frames)
        new_samples.extend([0] * SAMPLE_PADDING)
        sample_end = offset + len(frames)
        new_headers.append(name + struct.pack('<IIIIIBbHH', offset, sample_end, offset,
                                              sample_end, rate, root, correction, 0, 1))
        new_ibag.append((len(new_igen), 0))
        new_igen.append((KEY_RANGE, low | (high << 8)))  # keyRange comes first
        new_igen.extend(others)
        new_igen.append((SAMPLE_ID, index))  # sampleID comes last
    new_ibag.append((len(new_igen), 0))
    new_igen.append((0, 0))
    new_headers.append(b'EOS'.ljust(20, b'\0') + bytes(SHDR_SIZE - 20))

    imod = _records(pdta[b'imod'], 10)
    if len(imod) != 1:  # only the terminal record: every zone points to index 0
        raise SoundFontError('instrument modulators are not supported')
    instrument_name = instruments[0][:20]
    new_inst = (instrument_name + struct.pack('<H', 0)
                + b'EOI'.ljust(20, b'\0') + struct.pack('<H', len(new_ibag) - 1))

    if sys.byteorder == 'big':
        new_samples.byteswap()
    comment = (info.get(b'ICMT', b'').rstrip(b'\0').decode('latin1')
               + f' | Reduced by aelf-flutter tool/shrink_soundfont.py: keys '
               f'{low_key}-{high_key}, {seconds:g} s, {rate} Hz').encode('latin1') + b'\0'
    info_chunks = [_chunk(chunk_id, payload if chunk_id != b'ICMT' else comment)
                   for chunk_id, payload in info.items()]
    if b'ICMT' not in info:
        info_chunks.append(_chunk(b'ICMT', comment))
    pdta_chunks = [
        _chunk(b'phdr', pdta[b'phdr']), _chunk(b'pbag', pdta[b'pbag']),
        _chunk(b'pmod', pdta[b'pmod']), _chunk(b'pgen', pdta[b'pgen']),
        _chunk(b'inst', new_inst),
        _chunk(b'ibag', b''.join(struct.pack('<HH', *b) for b in new_ibag)),
        _chunk(b'imod', pdta[b'imod']),
        _chunk(b'igen', b''.join(struct.pack('<HH', *g) for g in new_igen)),
        _chunk(b'shdr', b''.join(new_headers)),
    ]
    body = (b'sfbk' + _list(b'INFO', info_chunks)
            + _list(b'sdta', [_chunk(b'smpl', new_samples.tobytes())])
            + _list(b'pdta', pdta_chunks))
    return b'RIFF' + struct.pack('<I', len(body)) + body


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--low-key', type=int, default=45, help='lowest key kept (default A2)')
    parser.add_argument('--high-key', type=int, default=76, help='highest key kept (default E5)')
    parser.add_argument('--seconds', type=float, default=2.0, help='sample length kept')
    parser.add_argument('--fade', type=float, default=0.3, help='fade-out length, in seconds')
    parser.add_argument('--keep-rate', action='store_true', help='do not halve the sample rate')
    args = parser.parse_args()
    try:
        result = shrink(args.source.read_bytes(), args.low_key, args.high_key,
                        args.seconds, args.fade, halve=not args.keep_rate)
    except SoundFontError as error:
        print(f'[ERROR] {error}', file=sys.stderr)
        return 1
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(result)
    print(f'{args.source.stat().st_size // 1024} KB -> {len(result) // 1024} KB: {args.output}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
