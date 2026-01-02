import { useState } from 'react';
import './Stage2.css';

export default function Stage2({ rankings, labelToModel, aggregateRankings }) {
  const [showDetails, setShowDetails] = useState(false);

  if (!rankings || rankings.length === 0) return null;

  const sortedRankings = aggregateRankings 
    ? Object.entries(aggregateRankings).sort(([, a], [, b]) => a - b).map(([model, score], i) => ({ model, score, rank: i + 1 }))
    : [];

  const getMedal = (rank) => rank === 1 ? '🥇' : rank === 2 ? '🥈' : rank === 3 ? '🥉' : `#${rank}`;

  return (
    <div className="stage stage2">
      <div className="stage-header">
        <h3 className="stage-title">Stage 2: Peer Rankings</h3>
        <button onClick={() => setShowDetails(!showDetails)}>{showDetails ? 'Hide' : 'Show'} Details</button>
      </div>
      
      {sortedRankings.length > 0 && (
        <div className="rankings-list">
          {sortedRankings.map(({ model, score, rank }) => (
            <div key={model} className={`ranking-item rank-${rank}`}>
              <span className="rank-medal">{getMedal(rank)}</span>
              <span className="rank-model">{model}</span>
              <span className="rank-score">Score: {score.toFixed(1)}</span>
            </div>
          ))}
        </div>
      )}

      {showDetails && (
        <div className="detailed-rankings">
          {rankings.map((ranking, i) => (
            <div key={i} className="ranking-card">
              <div className="ranking-card-header">{ranking.model}'s Assessment</div>
              <div className="ranking-card-body">{ranking.ranking}</div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
