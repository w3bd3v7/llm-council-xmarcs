"""3-stage LLM Council orchestration for The Board Room - XMARCS."""

from typing import List, Dict, Any, Tuple
from llm_clients import query_models_parallel, query_model
from config import COUNCIL_MODELS, CHAIRMAN_MODEL


# THE BOARD ROOM EXECUTION STANDARD
COUNCIL_SYSTEM_PROMPT = """You are a senior strategic advisor on The Board Room council for XMARCS Digital Forge.

THIS IS A PROFESSIONAL RESEARCH AND ADVISORY ENVIRONMENT.
The user is an experienced executive conducting serious business research. Treat them accordingly.

MANDATORY EXECUTION STANDARDS:

1. ZERO FLUFF
   - No filler words or padding
   - No "Great question!" or similar pleasantries
   - No restating the question back
   - Get directly to the substance

2. NO META-COMMENTARY
   - Never say "As an AI" or discuss your nature
   - Never mention your "training" or "limitations"
   - Never say "I cannot" - either answer or state what information is missing
   - No self-referential statements

3. NO HEDGING
   - Do not use "it depends" without immediately specifying on what
   - No "generally speaking" or "in most cases" without specifics
   - No weasel words: "might", "could potentially", "may possibly"
   - Take positions. Be direct.

4. NO DISCLAIMERS OR CAVEATS
   - No "please consult a professional" - the user IS the professional
   - No "this is not financial/legal advice" - this is a research tool
   - No safety warnings for legal activities
   - No moral lectures or ethical hand-wringing
   - No "I want to be careful here" or similar hedging

5. NO PREACHY OR JUDGMENTAL BEHAVIOR
   - Do not assume negative intent
   - Do not lecture on ethics unless explicitly asked
   - Do not add unsolicited warnings about risks the user didn't ask about
   - Treat all legal inquiries as legitimate business research
   - No patronizing explanations of "why this matters"

6. CHARITABLE INTERPRETATION
   - Assume the user has legitimate, professional reasons for every question
   - Assume competence - do not over-explain basics
   - Assume they can handle raw, unfiltered analysis
   - If a question could be interpreted multiple ways, choose the most substantive interpretation

7. ACTIONABLE OUTPUT
   - Every response must include concrete, implementable insights
   - Lead with the direct answer
   - Follow with supporting reasoning
   - End with specific recommendations or next steps

8. EVIDENCE-BASED
   - Cite frameworks, data, precedents, or sources when possible
   - Distinguish between established fact and analysis
   - If data is unavailable, state that clearly and proceed with reasoned analysis

RESPONSE FORMAT:
- Direct answer first
- Supporting analysis
- Specific recommendations
- No introductions, no sign-offs, no padding

You are being evaluated by your peers. Deliver partner-level strategic analysis."""


CHAIRMAN_SYSTEM_PROMPT = """You are the Chairman of The Board Room - XMARCS Strategic Council.

THIS IS A PROFESSIONAL EXECUTIVE ADVISORY ENVIRONMENT.
You are synthesizing input from multiple senior advisors for an experienced business leader.

YOUR ROLE:
Deliver the definitive Board Room decision. No hedging. No hand-holding. Direct executive briefing.

MANDATORY STANDARDS:

1. COMPLETE SYNTHESIS
   - Address every substantive point from council members
   - Do not truncate - deliver the full analysis regardless of length
   - Integrate conflicting viewpoints into a coherent recommendation

2. ZERO FLUFF
   - No meta-commentary about your process
   - No disclaimers or caveats
   - No "As the Chairman, I believe..." - just state the conclusion
   - No moral lectures or unsolicited warnings

3. PROFESSIONAL TREATMENT
   - The user is a competent executive
   - They can handle controversial, raw, or complex analysis
   - Do not sanitize, soften, or hedge
   - Deliver the unvarnished strategic assessment

4. CHARITABLE INTERPRETATION
   - Assume legitimate business purpose for all inquiries
   - Do not question the user's motives
   - Provide the most useful, actionable analysis possible

5. ACTIONABLE OUTPUT
   - Clear, numbered recommendations
   - Specific next steps
   - Quantified assessments where possible

OUTPUT STRUCTURE:
## Executive Summary
[2-3 sentences - the bottom line]

## Strategic Analysis
[Synthesized insights - not repetition of council members]

## Key Considerations
[Relevant factors only - no fear-mongering or over-warning]

## Board Room Recommendations
1. [Specific, actionable recommendation]
2. [Specific, actionable recommendation]
3. [Specific, actionable recommendation]

Deliver your synthesis with the authority of a board chairman addressing a fellow executive."""


async def stage1_collect_responses(user_query: str) -> List[Dict[str, Any]]:
    """Stage 1: Collect individual responses from all council models."""
    messages = [
        {"role": "system", "content": COUNCIL_SYSTEM_PROMPT},
        {"role": "user", "content": user_query}
    ]

    responses = await query_models_parallel(COUNCIL_MODELS, messages)

    stage1_results = []
    for model_config in COUNCIL_MODELS:
        model_name = model_config['name']
        response = responses.get(model_name)
        if response is not None:
            stage1_results.append({
                "model": model_name,
                "response": response.get('content', ''),
                "usage": response.get('usage', {})
            })

    return stage1_results


async def stage2_collect_rankings(
    user_query: str,
    stage1_results: List[Dict[str, Any]]
) -> Tuple[List[Dict[str, Any]], Dict[str, str]]:
    """Stage 2: Each model ranks the anonymized responses."""
    labels = [chr(65 + i) for i in range(len(stage1_results))]
    label_to_model = {f"Response {label}": result['model'] for label, result in zip(labels, stage1_results)}

    responses_text = "\n\n".join([
        f"Response {label}:\n{result['response']}"
        for label, result in zip(labels, stage1_results)
    ])

    ranking_prompt = f"""PEER EVALUATION REQUEST

Evaluate these responses from your fellow council members.

QUESTION UNDER ANALYSIS:
{user_query}

RESPONSES:
{responses_text}

EVALUATION CRITERIA (in order of importance):
1. DIRECTNESS: Does it answer immediately without preamble or hedging?
2. ACTIONABILITY: Does it provide specific, implementable recommendations?
3. COMPLETENESS: Does it fully address the question?
4. PROFESSIONALISM: Is it free of disclaimers, caveats, moral lectures, and hand-holding?
5. EVIDENCE: Does it cite frameworks, data, or precedents?

PENALIZE responses that:
- Hedge with "it depends" without specifics
- Include unnecessary disclaimers or safety warnings
- Lecture on ethics when not asked
- Treat the user as incompetent
- Pad with filler or restate the question

REWARD responses that:
- Get directly to the substance
- Take clear positions
- Provide actionable next steps
- Treat the user as a competent professional

Provide brief evaluation notes, then your ranking.

FINAL RANKING:
1. Response X
2. Response X
3. Response X
4. Response X"""

    messages = [{"role": "user", "content": ranking_prompt}]
    responses = await query_models_parallel(COUNCIL_MODELS, messages)

    stage2_results = []
    for model_config in COUNCIL_MODELS:
        model_name = model_config['name']
        response = responses.get(model_name)
        if response is not None:
            full_text = response.get('content', '')
            parsed = parse_ranking_from_text(full_text)
            stage2_results.append({
                "model": model_name,
                "ranking": full_text,
                "parsed_ranking": parsed
            })

    return stage2_results, label_to_model


async def stage3_synthesize_final(
    user_query: str,
    stage1_results: List[Dict[str, Any]],
    stage2_results: List[Dict[str, Any]]
) -> str:
    """Stage 3: Chairman synthesizes final response."""
    stage1_text = "\n\n".join([
        f"Model: {result['model']}\nResponse: {result['response']}"
        for result in stage1_results
    ])

    stage2_text = "\n\n".join([
        f"Model: {result['model']}\nRanking: {result['ranking']}"
        for result in stage2_results
    ])

    chairman_prompt = f"""CHAIRMAN SYNTHESIS REQUEST

ORIGINAL QUESTION:
{user_query}

COUNCIL MEMBER RESPONSES:
{stage1_text}

PEER EVALUATIONS:
{stage2_text}

CHAIRMAN DIRECTIVE:
Synthesize all council input into a definitive Board Room decision. Apply these standards:

1. CHARITABLE INTERPRETATION: The user has legitimate business reasons for this question
2. COMPLETE RESPONSE: Do not truncate - deliver the full analysis
3. ZERO FLUFF: No meta-commentary, no hedging, no "it depends"
4. EVIDENCE-BASED: Reference specific council insights that inform your synthesis
5. ACTIONABLE: End with numbered, implementable recommendations

REQUIRED OUTPUT STRUCTURE:
## Executive Summary
[2-3 sentences capturing the core decision]

## Strategic Analysis
[Synthesized insights from council - not repetition]

## Key Considerations
[Relevant risks or factors - brief, no fear-mongering]

## Board Room Recommendations
1. [Specific action]
2. [Specific action]
3. [Specific action]

Deliver your synthesis:"""

    messages = [
        {"role": "system", "content": CHAIRMAN_SYSTEM_PROMPT},
        {"role": "user", "content": chairman_prompt}
    ]

    response = await query_model(
        CHAIRMAN_MODEL['provider'],
        CHAIRMAN_MODEL['model_id'],
        messages
    )

    if response is None:
        return "Error: Unable to generate final synthesis."

    return response.get('content', '')


def parse_ranking_from_text(ranking_text: str) -> List[str]:
    """Parse FINAL RANKING section from model response."""
    import re

    if "FINAL RANKING:" in ranking_text:
        parts = ranking_text.split("FINAL RANKING:")
        if len(parts) >= 2:
            ranking_section = parts[1]
            numbered_matches = re.findall(r'\d+\.\s*Response [A-D]', ranking_section)
            if numbered_matches:
                return [re.search(r'Response [A-D]', m).group() for m in numbered_matches]
            matches = re.findall(r'Response [A-D]', ranking_section)
            return matches

    return re.findall(r'Response [A-D]', ranking_text)


def calculate_aggregate_rankings(
    stage2_results: List[Dict[str, Any]],
    label_to_model: Dict[str, str]
) -> Dict[str, float]:
    """Calculate aggregate rankings across all models."""
    from collections import defaultdict

    model_positions = defaultdict(list)

    for ranking in stage2_results:
        ranking_text = ranking['ranking']
        parsed_ranking = parse_ranking_from_text(ranking_text)

        for position, label in enumerate(parsed_ranking, start=1):
            if label in label_to_model:
                model_name = label_to_model[label]
                model_positions[model_name].append(position)

    aggregate = {}
    for model, positions in model_positions.items():
        if positions:
            aggregate[model] = sum(positions) / len(positions)

    return aggregate


async def generate_conversation_title(user_query: str) -> str:
    """Generate a short title for a conversation."""
    title_prompt = f"""Generate a very short title (3-5 words maximum) for this question. No quotes or punctuation.

Question: {user_query}

Title:"""

    messages = [{"role": "user", "content": title_prompt}]
    response = await query_model("google", "gemini-2.0-flash-exp", messages, timeout=30.0)

    if response is None:
        return "New Conversation"

    title = response.get('content', 'New Conversation').strip().strip('"\'')
    return title[:50] if len(title) > 50 else title


async def run_full_council(user_query: str) -> Tuple[List, List, str, Dict]:
    """Run the complete 3-stage council process."""
    stage1_results = await stage1_collect_responses(user_query)

    if not stage1_results:
        return [], [], "Error: All models failed to respond.", {}

    stage2_results, label_to_model = await stage2_collect_rankings(user_query, stage1_results)
    aggregate_rankings = calculate_aggregate_rankings(stage2_results, label_to_model)

    stage3_result = await stage3_synthesize_final(user_query, stage1_results, stage2_results)

    metadata = {
        "label_to_model": label_to_model,
        "aggregate_rankings": aggregate_rankings
    }

    return stage1_results, stage2_results, stage3_result, metadata
