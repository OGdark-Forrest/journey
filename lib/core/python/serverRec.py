from fastapi import APIRouter
from .model import getModelOutput

from collections import Counter, defaultdict
from datetime import datetime, timedelta

BLOCK_NAMES = {0: "night", 1: "morning", 2: "afternoon", 3: "evening"}
router = APIRouter()

def time_block(hour: int) -> int:
    if 5 <= hour < 12:  return 1
    if 12 <= hour < 17: return 2
    if 17 <= hour < 22: return 3
    return 0


# ---------- formatting helpers ----------

def _fmt_goals(goals: dict[str, list[str]]) -> str:
    lines = []
    for period in ("daily", "weekly", "monthly"):
        items = goals.get(period) or []
        lines.append(f"{period.capitalize()}: " + ("; ".join(items) if items else "none set"))
    return "\n".join(lines)


def _fmt_user_info(user_info: list[tuple[str, str]]) -> str:
    return "\n".join(f"- {p}: {o}" for p, o in user_info) or "none provided"


def _fmt_logs(logs: list[tuple[int, datetime, str, str]], limit: int = 150) -> str:
    rows = sorted(logs, key=lambda l: l[1])[-limit:]
    return "\n".join(
        f"{ts:%a %Y-%m-%d %H:%M} ({BLOCK_NAMES[time_block(ts.hour)]}) | {action} | felt: {feeling}"
        for _id, ts, action, feeling in rows
    ) or "no logs"


def _window_counts(logs, end: datetime, days: int) -> str:
    start = end - timedelta(days=days)
    counts = Counter(action for _id, ts, action, _f in logs if start < ts <= end)
    return ", ".join(f"{a} x{n}" for a, n in counts.most_common()) or "nothing logged"


def _progress_block(logs, end: datetime) -> str:
    return (
        f"Last 7 days: {_window_counts(logs, end, 7)}\n"
        f"Last 30 days: {_window_counts(logs, end, 30)}"
    )


# ---------- reflection (previous / current day) ----------

def getReflection(
    logs: list[tuple[int, datetime, str, str]],       # (id, timestamp, action, feeling)
    user_info: list[tuple[str, str]],                 # (prompt, option)
    goals: dict[str, list[str]],                      # {"daily": [...], "weekly": [...], "monthly": [...]}
    day: datetime | None = None,                      # day to reflect on (default: today)
) -> str:
    day = day or datetime.now()
    day_logs = [l for l in logs if l[1].date() == day.date()]
    if not day_logs:
        return f"No activity was logged for {day:%A, %B %d}, so there's nothing to reflect on yet."

    end_of_day = datetime.combine(day.date(), datetime.max.time())

    prompt = f"""You are a supportive, honest personal reflection coach.
Reflect on the user's day using ONLY the data below. Reference specific logged
actions and times. Do not invent activities. If the data is thin, say so.

ABOUT THE USER
{_fmt_user_info(user_info)}

GOALS
{_fmt_goals(goals)}

TODAY'S LOG ({day:%A %Y-%m-%d}), each line: time | action | how the user felt
{_fmt_logs(day_logs)}

PROGRESS CONTEXT (action counts, for judging weekly/monthly goals)
{_progress_block(logs, end_of_day)}

Write the reflection with exactly these three headings:

## Goal alignment
Where the day matched the daily goal and where it deviated. Note any effect on
the weekly/monthly goals. Be specific, and credit what went well.

## Overall feeling
A happiness score from 1-10 and 2-3 sentences explaining it, based on the
feelings logged and how they changed through the day.

## What could have been better
2-4 concrete, kind, actionable tips. No lecturing.
"""
    return getModelOutput(prompt)


# ---------- recommendations (future day planning) ----------

def getRecommendations(
    logs: list[tuple[int, datetime, str, str]],
    user_info: list[tuple[str, str]],
    goals: dict[str, list[str]],
    day: datetime | None = None,                      # day to plan (default: tomorrow)
    suggestions: dict[str, list[str]] | None = None,  # optional: {"morning": [...], ...} from suggest_actions
) -> str:
    now = datetime.now()
    day = day or (now + timedelta(days=1))

    # Habits on the same weekday, by time block (last 8 weeks)
    cutoff = day - timedelta(weeks=8)
    by_block = defaultdict(Counter)
    for _id, ts, action, _f in logs:
        if ts.weekday() == day.weekday() and ts >= cutoff:
            by_block[BLOCK_NAMES[time_block(ts.hour)]][action] += 1
    weekday_habits = "\n".join(
        f"- {block}: " + ", ".join(f"{a} x{n}" for a, n in c.most_common(4))
        for block, c in by_block.items()
    ) or "no history for this weekday"

    suggestion_text = ""
    if suggestions:
        suggestion_text = "\nPREDICTED LIKELY ACTIONS (from the user's patterns)\n" + "\n".join(
            f"- {block}: {', '.join(acts)}" for block, acts in suggestions.items()
        ) + "\n"

    recent_start = now - timedelta(days=14)
    recent = [l for l in logs if l[1] >= recent_start]

    prompt = f"""You are a practical, encouraging day-planning assistant.
Plan {day:%A %Y-%m-%d} for the user using ONLY the data below. Build on their
real habits and what they felt good about, and keep the plan realistic. If the
data is thin, say so and keep the plan simple.

ABOUT THE USER
{_fmt_user_info(user_info)}

GOALS
{_fmt_goals(goals)}

RECENT LOG (last 14 days), each line: time | action | how the user felt
{_fmt_logs(recent)}

HABITS ON {day:%A}s (last 8 weeks)
{weekday_habits}
{suggestion_text}
PROGRESS CONTEXT (action counts, for judging weekly/monthly goals)
{_progress_block(logs, now)}

Write the plan with exactly these two headings:

## Day plan
An agenda split into morning, afternoon, and evening, with 1-3 items each.
Favor actions the user has felt good about and routines they already keep.

## Goal focus
State whether this should be a push day, a balanced day, or a rest day, and
why, based on goal progress and recent feelings. Name the one or two things
that would do the most for their goals today.
"""
    return getModelOutput(prompt)

Log = tuple[int, datetime, str, str]                  # (id, timestamp, action, feeling)


class Goals(BaseModel):
    daily: list[str] = []
    weekly: list[str] = []
    monthly: list[str] = []


class InsightRequest(BaseModel):
    logs: list[Log]
    user_info: list[tuple[str, str]] = []             # (prompt, option)
    goals: Goals = Goals()
    day: datetime | None = None                       # reflect: day to review; plan: day to plan


class RecommendRequest(InsightRequest):
    # optional: pass these and the server computes predicted actions per time block
    defaults_by_block: dict[int, list[str]] | None = None
    feeling_weights: dict[str, float] | None = None


class TextResponse(BaseModel):
    text: str


@router.post("/reflection", response_model=TextResponse)
def reflection(req: InsightRequest):
    try:
        text = getReflection(req.logs, req.user_info, req.goals.model_dump(), day=req.day)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Model call failed: {e}")
    return {"text": text}


@router.post("/recommendations", response_model=TextResponse)
def recommendations(req: RecommendRequest):
    suggestions = None
    if req.defaults_by_block is not None:
        # Predict likely actions for a representative hour of each block on the planned day
        base = req.day or datetime.now()
        suggestions = {
            name: suggest_actions(
                req.logs,
                req.defaults_by_block,
                now=base.replace(hour=hour, minute=0, second=0, microsecond=0),
                feeling_weights=req.feeling_weights,
            )
            for name, hour in (("morning", 8), ("afternoon", 14), ("evening", 19))
        }
    try:
        text = getRecommendations(
            req.logs, req.user_info, req.goals.model_dump(),
            day=req.day, suggestions=suggestions,
        )
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Model call failed: {e}")
    return {"text": text}