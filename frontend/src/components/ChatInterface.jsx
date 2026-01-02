import { useState, useEffect, useRef } from 'react';
import ReactMarkdown from 'react-markdown';
import Stage1 from './Stage1';
import Stage2 from './Stage2';
import Stage3 from './Stage3';
import './ChatInterface.css';

export default function ChatInterface({ conversation, onSendMessage, isLoading }) {
  const [input, setInput] = useState('');
  const messagesEndRef = useRef(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [conversation]);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (input.trim() && !isLoading) {
      onSendMessage(input);
      setInput('');
    }
  };

  if (!conversation) {
    return (
      <div className="chat-interface">
        <div className="empty-state">
          <h2>Welcome to The Board Room</h2>
          <p>Your strategic AI council awaits. Create a new session to begin.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="chat-interface">
      <div className="messages-container">
        {conversation.messages.length === 0 ? (
          <div className="empty-state">
            <h2>Start Your Session</h2>
            <p>Present your strategic question to The Board Room council.</p>
          </div>
        ) : (
          conversation.messages.map((msg, index) => (
            <div key={index} className="message-group">
              {msg.role === 'user' ? (
                <div className="user-message">
                  <div className="message-label">You</div>
                  <div className="message-content">
                    <ReactMarkdown>{msg.content}</ReactMarkdown>
                  </div>
                </div>
              ) : (
                <div className="assistant-message">
                  <div className="message-label">The Board Room</div>
                  {msg.loading?.stage1 && <div className="stage-loading"><div className="spinner"></div><span>Stage 1: Gathering Council Perspectives...</span></div>}
                  {msg.stage1 && <Stage1 responses={msg.stage1} />}
                  {msg.loading?.stage2 && <div className="stage-loading"><div className="spinner"></div><span>Stage 2: Peer Rankings...</span></div>}
                  {msg.stage2 && <Stage2 rankings={msg.stage2} labelToModel={msg.metadata?.label_to_model} aggregateRankings={msg.metadata?.aggregate_rankings} />}
                  {msg.loading?.stage3 && <div className="stage-loading"><div className="spinner"></div><span>Stage 3: Chairman Synthesis...</span></div>}
                  {msg.stage3 && <Stage3 finalResponse={msg.stage3} />}
                </div>
              )}
            </div>
          ))
        )}
        <div ref={messagesEndRef} />
      </div>

      {conversation && (
        <form className="input-form" onSubmit={handleSubmit}>
          <textarea
            className="message-input"
            placeholder="Present your strategic question..."
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); handleSubmit(e); } }}
            disabled={isLoading}
            rows={2}
          />
          <button type="submit" className="send-button" disabled={!input.trim() || isLoading}>
            {isLoading ? <div className="spinner"></div> : 'Send'}
          </button>
        </form>
      )}
    </div>
  );
}
