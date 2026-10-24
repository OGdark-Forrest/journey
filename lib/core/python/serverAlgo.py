import math
from collections import defaultdict
from datetime import datetime


def time_block(hour: int) -> int:
    if 5 <= hour < 12:  return 1   # morning
    if 12 <= hour < 17: return 2   # afternoon
    if 17 <= hour < 22: return 3   # evening
    return 0                       # night


def suggest(
    logs: list[tuple[int, datetime, str, str]],   # (id, timestamp, prompt, response)
    prompt: str,
    defaults: dict[str, list[str]],               # missing/empty for custom prompts
    now: datetime | None = None,
    k: int = 4,
    half_life_days: float = 14.0,
    slot_half_life_days: float = 42.0,   # same weekday + same block decays slower
    prior_strength: float = 1.0,
    burst_cap: int = 3,                  # max picks per (response, day) that count
    dominant_share: float = 0.6,
    min_history: int = 5,
    shift_threshold: int = 3,            # distinct days before a new response is trusted
    penalty: float = 0.1,
) -> list[str]:
    now = now or datetime.now()
    options = defaults.get(prompt, [])

    seen_ids = set()
    events = defaultdict(list)           # (response, date) -> [weights]
    relevant_days = defaultdict(set)     # response -> distinct context-relevant days

    for log_id, ts, p, response in logs:
        if p != prompt or ts > now or log_id in seen_ids:
            continue                     # wrong prompt, future timestamp, duplicate id
        seen_ids.add(log_id)

        age_days = (now - ts).total_seconds() / 86400

        d = abs(time_block(ts.hour) - time_block(now.hour))
        block_sim = {0: 1.0, 1: 0.3, 2: 0.0}[min(d, 4 - d)]

        same_day = ts.weekday() == now.weekday()
        same_type = (ts.weekday() >= 5) == (now.weekday() >= 5)
        day_sim = 1.0 if same_day else (0.3 if same_type else 0.0)

        exact_slot = same_day and block_sim == 1.0
        recency = 0.5 ** (age_days / (slot_half_life_days if exact_slot else half_life_days))
        context = 1 + 0.5 * block_sim + 0.25 * day_sim + (1.0 if exact_slot else 0.0)

        events[(response, ts.date())].append(recency * context)

        if same_type and block_sim > 0:
            relevant_days[response].add(ts.date())

    # Burst cap: spam-clicking on one day can't dominate
    scores = defaultdict(float)
    for (response, _day), weights in events.items():
        scores[response] += sum(sorted(weights, reverse=True)[:burst_cap])

    # Pattern-aware anomaly gate (log scores only, never the prior)
    counts = {r: len(days) for r, days in relevant_days.items()}
    total = sum(counts.values())
    if total >= min_history:
        top = max(counts, key=counts.get)
        if counts[top] / total >= dominant_share:
            for r in scores:
                if r != top and counts.get(r, 0) < shift_threshold:
                    scores[r] *= penalty

    # Default order as a weak prior (default prompts only)
    n = len(options)
    for i, opt in enumerate(options):
        scores[opt] += prior_strength * (n - i) / n

    default_rank = {opt: i for i, opt in enumerate(options)}
    ranked = sorted(scores, key=lambda r: (-scores[r], default_rank.get(r, n)))
    return ranked[:k]