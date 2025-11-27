from fastapi import APIRouter
from pydantic import BaseModel, Field

router = APIRouter(prefix="/analysis")


class AnalysisRequest(BaseModel):
    deck_id: str
    deck_state: dict | None = None


class ProbabilityResult(BaseModel):
    question: str
    value: str


class AnalysisResponse(BaseModel):
    mana_curve_buckets: dict[str, int] = Field(default_factory=dict)
    color_pips_by_color: dict[str, int] = Field(default_factory=dict)
    ramp_count: int = 0
    draw_count: int = 0
    interaction_count: int = 0
    protection_count: int = 0
    wincon_count: int = 0
    land_count: int = 0
    probability_questions: list[ProbabilityResult] = Field(default_factory=list)
    warnings: list[str] = Field(default_factory=list)


@router.post("", response_model=AnalysisResponse)
def analyze(request: AnalysisRequest) -> AnalysisResponse:
    # TODO: Hook up real combinatorics + OpenAI explanation
    return AnalysisResponse(
        mana_curve_buckets={
            "0": 5,
            "1": 12,
            "2": 18,
            "3": 20,
            "4": 16,
            "5": 10,
            "6": 8,
            "7+": 11,
        },
        color_pips_by_color={"W": 15, "U": 25, "B": 12, "R": 18, "G": 20},
        ramp_count=10,
        draw_count=9,
        interaction_count=12,
        protection_count=4,
        wincon_count=4,
        land_count=38,
        probability_questions=[
            ProbabilityResult(question="3+ Laender bis Zug 3", value="68%"),
            ProbabilityResult(question="1 Ramp in den ersten 10 Karten", value="74%"),
            ProbabilityResult(question="Commander bis Zug 5 casten", value="81%"),
        ],
        warnings=["Curve leicht top-heavy.", "Wincons koennten klarer definiert werden."],
    )
