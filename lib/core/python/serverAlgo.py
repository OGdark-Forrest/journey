import math
from collections import defaultdict
from datetime import datetime
from fastapi import APIRouter, HTTPException

router = APIRouter

class OptionsRequest(BaseModel):
    prompt: str
    now: datetime | None = None
    defOptions: list[str] = []
    logs: list[tuple[int, datetime, str, str]]

def time_block(hour: int) -> int:
    if 5 <= hour < 12:  return 1   # morning
    if 12 <= hour < 17: return 2   # afternoon
    if 17 <= hour < 22: return 3   # evening
    return 0                       # night

def suggest_actions(
    logs: list[tuple[int, datetime, str, str]],   # (id, timestamp, action, feeling)
    defaults_by_block: dict[int, list[str]],      # time_block -> default actions, best first
    now: datetime | None = None,
    k: int = 4,
    feeling_weights: dict[str, float] | None = None,  # optional, e.g. {"good": 1.2, "bad": 0.5}
    half_life_days: float = 14.0,
    slot_half_life_days: float = 42.0,   # same weekday + same block decays slower
    prior_strength: float = 1.0,
    burst_cap: int = 3,                  # max logs per (action, day) that count
    dominant_share: float = 0.6,
    min_history: int = 5,
    shift_threshold: int = 3,            # distinct days before a new action is trusted
    penalty: float = 0.1,
) -> list[str]:
    now = now or datetime.now()
    options = defaults_by_block.get(time_block(now.hour), [])

    seen_ids = set()
    events = defaultdict(list)           # (action, date) -> [weights]
    relevant_days = defaultdict(set)     # action -> distinct context-relevant days

    for log_id, ts, action, feeling in logs:
        if ts > now or log_id in seen_ids:
            continue                     # future timestamp or duplicate id
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
        mood = max(0.0, (feeling_weights or {}).get(feeling, 1.0))

        events[(action, ts.date())].append(recency * context * mood)

        if same_type and block_sim > 0:
            relevant_days[action].add(ts.date())

    # Burst cap: spam-logging one action in a day can't dominate
    scores = defaultdict(float)
    for (action, _day), weights in events.items():
        scores[action] += sum(sorted(weights, reverse=True)[:burst_cap])

    # Pattern-aware anomaly gate (log scores only, never the prior)
    counts = {a: len(days) for a, days in relevant_days.items()}
    total = sum(counts.values())
    if total >= min_history:
        top = max(counts, key=counts.get)
        if counts[top] / total >= dominant_share:
            for a in scores:
                if a != top and counts.get(a, 0) < shift_threshold:
                    scores[a] *= penalty

    # Default actions for this time block act as a weak prior
    n = len(options)
    for i, opt in enumerate(options):
        scores[opt] += prior_strength * (n - i) / n

    default_rank = {opt: i for i, opt in enumerate(options)}
    ranked = sorted(scores, key=lambda a: (-scores[a], default_rank.get(a, n)))
    return ranked[:k]

@router.post("/getOptions")
def getOptions(req: OptionsRequest):
    listOfOptions = suggest(req.logs, req.prompt, {datetime(req.now).hour(): req.defOptions}, now=req.now)

    return {
        "code": 200,
        "detail": listOfOptions
    }