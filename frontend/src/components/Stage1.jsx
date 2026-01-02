import { useState } from 'react';
import ReactMarkdown from 'react-markdown';
import './Stage1.css';

export default function Stage1({ responses }) {
  const [expanded, setExpanded] = useState(null);

  if (!responses || responses.length === 0) return null;

  return (
    <div className="stage stage1">
      <h3 className="stage-title">Stage 1: Council Perspectives</h3>
      <div className="responses-grid">
        {responses.map((resp, index) => (
          <div key={index} className={`response-card ${expanded === index ? 'expanded' : ''}`}>
            <div className="response-header" onClick={() => setExpanded(expanded === index ? null : index)}>
              <span className="model-name">{resp.model}</span>
              <span className="expand-btn">{expanded === index ? '−' : '+'}</span>
            </div>
            {expanded === index && (
              <div className="response-body">
                <ReactMarkdown>{resp.response}</ReactMarkdown>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
