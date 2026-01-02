import { useState } from 'react';
import './Sidebar.css';

export default function Sidebar({
  conversations, currentConversationId, onSelectConversation, onNewConversation,
  onDeleteConversation, onRenameConversation, onExportConversation, darkMode, onToggleDarkMode,
}) {
  const [editingId, setEditingId] = useState(null);
  const [editTitle, setEditTitle] = useState('');
  const [menuOpenId, setMenuOpenId] = useState(null);

  return (
    <div className="sidebar">
      <div className="sidebar-header">
        <div className="brand">
          <div className="brand-icon">⚡</div>
          <div className="brand-text">
            <h1>The Board Room</h1>
            <span className="brand-tagline">XMARCS Strategic Council</span>
          </div>
        </div>
        <button className="theme-toggle" onClick={onToggleDarkMode}>
          {darkMode ? '☀️' : '🌙'}
        </button>
      </div>

      <button className="new-session-btn" onClick={onNewConversation}>+ New Session</button>

      <div className="sessions-list">
        {conversations.map((conv) => (
          <div
            key={conv.id}
            className={`session-item ${conv.id === currentConversationId ? 'active' : ''}`}
            onClick={() => onSelectConversation(conv.id)}
          >
            {editingId === conv.id ? (
              <input
                type="text"
                className="rename-input"
                value={editTitle}
                onChange={(e) => setEditTitle(e.target.value)}
                onBlur={() => { onRenameConversation(conv.id, editTitle); setEditingId(null); }}
                onKeyDown={(e) => { if (e.key === 'Enter') { onRenameConversation(conv.id, editTitle); setEditingId(null); } }}
                autoFocus
                onClick={(e) => e.stopPropagation()}
              />
            ) : (
              <>
                <div className="session-content">
                  <div className="session-title">{conv.title || 'New Session'}</div>
                  <div className="session-meta">{conv.message_count} messages</div>
                </div>
                <div className="session-actions">
                  <button onClick={(e) => { e.stopPropagation(); setMenuOpenId(menuOpenId === conv.id ? null : conv.id); }}>⋮</button>
                  {menuOpenId === conv.id && (
                    <div className="action-menu" onClick={(e) => e.stopPropagation()}>
                      <button onClick={() => { setEditingId(conv.id); setEditTitle(conv.title || ''); setMenuOpenId(null); }}>Rename</button>
                      <button onClick={() => { onExportConversation(conv.id); setMenuOpenId(null); }}>Export</button>
                      <button className="danger" onClick={() => { onDeleteConversation(conv.id); setMenuOpenId(null); }}>Delete</button>
                    </div>
                  )}
                </div>
              </>
            )}
          </div>
        ))}
      </div>

      <div className="sidebar-footer">
        <span>Powered by <strong>XMARCS Digital Forge</strong></span>
      </div>
    </div>
  );
}
