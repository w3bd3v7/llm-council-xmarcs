import ReactMarkdown from 'react-markdown';
import './Stage3.css';

export default function Stage3({ finalResponse }) {
  if (!finalResponse) return <div className="stage stage3 error">Unable to generate synthesis.</div>;

  return (
    <div className="stage stage3">
      <div className="stage-header">
        <h3 className="stage-title">Stage 3: The Board Room Decision</h3>
        <span className="chairman-badge">Chairman GLM-4.7</span>
      </div>
      <div className="final-response">
        <ReactMarkdown>{finalResponse}</ReactMarkdown>
      </div>
      <div className="council-stamp">✓ Council Decision Rendered</div>
    </div>
  );
}
