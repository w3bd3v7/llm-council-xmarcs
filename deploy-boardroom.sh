#!/bin/bash
# THE BOARD ROOM - Complete Deployment Script
# XMARCS Digital Forge

set -e

echo "============================================"
echo "THE BOARD ROOM - Executive Edition Deployment"
echo "============================================"

cd /opt/llm-council-xmarcs

# Backup current files
echo "[1/6] Creating backup..."
mkdir -p /opt/llm-council-backup-$(date +%Y%m%d%H%M%S)
cp -r backend frontend /opt/llm-council-backup-$(date +%Y%m%d%H%M%S)/

# Remove old frontend src and backend files (except config with API keys)
echo "[2/6] Cleaning old files..."
rm -rf frontend/src/*
rm -f backend/council.py backend/main.py backend/storage.py backend/__init__.py
rm -f backend/llm_clients/*.py

# Create frontend/src/components directory
mkdir -p frontend/src/components

# ============================================
# FRONTEND FILES
# ============================================

echo "[3/6] Installing frontend files..."

# App.jsx
cat > frontend/src/App.jsx << 'APPJSX'
import { useState, useEffect } from 'react';
import Sidebar from './components/Sidebar';
import ChatInterface from './components/ChatInterface';
import { api } from './api';
import './App.css';

function App() {
  const [conversations, setConversations] = useState([]);
  const [currentConversationId, setCurrentConversationId] = useState(null);
  const [currentConversation, setCurrentConversation] = useState(null);
  const [isLoading, setIsLoading] = useState(false);
  const [darkMode, setDarkMode] = useState(() => {
    const saved = localStorage.getItem('boardroom-dark-mode');
    return saved ? JSON.parse(saved) : true;
  });

  useEffect(() => {
    document.body.classList.toggle('dark-mode', darkMode);
    localStorage.setItem('boardroom-dark-mode', JSON.stringify(darkMode));
  }, [darkMode]);

  useEffect(() => {
    loadConversations();
  }, []);

  useEffect(() => {
    if (currentConversationId) {
      loadConversation(currentConversationId);
    }
  }, [currentConversationId]);

  const loadConversations = async () => {
    try {
      const convs = await api.listConversations();
      setConversations(convs);
    } catch (error) {
      console.error('Failed to load conversations:', error);
    }
  };

  const loadConversation = async (id) => {
    try {
      const conv = await api.getConversation(id);
      setCurrentConversation(conv);
    } catch (error) {
      console.error('Failed to load conversation:', error);
    }
  };

  const handleNewConversation = async () => {
    try {
      const newConv = await api.createConversation();
      setConversations([
        { id: newConv.id, created_at: newConv.created_at, message_count: 0 },
        ...conversations,
      ]);
      setCurrentConversationId(newConv.id);
    } catch (error) {
      console.error('Failed to create conversation:', error);
    }
  };

  const handleSelectConversation = (id) => {
    setCurrentConversationId(id);
  };

  const handleDeleteConversation = async (id) => {
    if (!confirm('Delete this session?')) return;
    try {
      await api.deleteConversation(id);
      setConversations(conversations.filter(c => c.id !== id));
      if (currentConversationId === id) {
        setCurrentConversationId(null);
        setCurrentConversation(null);
      }
    } catch (error) {
      console.error('Failed to delete conversation:', error);
    }
  };

  const handleRenameConversation = async (id, newTitle) => {
    try {
      await api.renameConversation(id, newTitle);
      setConversations(conversations.map(c => 
        c.id === id ? { ...c, title: newTitle } : c
      ));
      if (currentConversation && currentConversation.id === id) {
        setCurrentConversation({ ...currentConversation, title: newTitle });
      }
    } catch (error) {
      console.error('Failed to rename conversation:', error);
    }
  };

  const handleExportConversation = async (id) => {
    try {
      const markdown = await api.exportConversation(id);
      const blob = new Blob([markdown], { type: 'text/markdown' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `boardroom-session-${id.slice(0, 8)}.md`;
      a.click();
      URL.revokeObjectURL(url);
    } catch (error) {
      console.error('Failed to export conversation:', error);
    }
  };

  const handleSendMessage = async (content) => {
    if (!currentConversationId) return;
    setIsLoading(true);
    try {
      const userMessage = { role: 'user', content };
      setCurrentConversation((prev) => ({
        ...prev,
        messages: [...prev.messages, userMessage],
      }));

      const assistantMessage = {
        role: 'assistant',
        stage1: null,
        stage2: null,
        stage3: null,
        metadata: null,
        loading: { stage1: false, stage2: false, stage3: false },
      };

      setCurrentConversation((prev) => ({
        ...prev,
        messages: [...prev.messages, assistantMessage],
      }));

      await api.sendMessageStream(currentConversationId, content, (eventType, event) => {
        switch (eventType) {
          case 'stage1_start':
            setCurrentConversation((prev) => {
              const messages = [...prev.messages];
              messages[messages.length - 1].loading.stage1 = true;
              return { ...prev, messages };
            });
            break;
          case 'stage1_complete':
            setCurrentConversation((prev) => {
              const messages = [...prev.messages];
              messages[messages.length - 1].stage1 = event.data;
              messages[messages.length - 1].loading.stage1 = false;
              return { ...prev, messages };
            });
            break;
          case 'stage2_start':
            setCurrentConversation((prev) => {
              const messages = [...prev.messages];
              messages[messages.length - 1].loading.stage2 = true;
              return { ...prev, messages };
            });
            break;
          case 'stage2_complete':
            setCurrentConversation((prev) => {
              const messages = [...prev.messages];
              messages[messages.length - 1].stage2 = event.data;
              messages[messages.length - 1].metadata = event.metadata;
              messages[messages.length - 1].loading.stage2 = false;
              return { ...prev, messages };
            });
            break;
          case 'stage3_start':
            setCurrentConversation((prev) => {
              const messages = [...prev.messages];
              messages[messages.length - 1].loading.stage3 = true;
              return { ...prev, messages };
            });
            break;
          case 'stage3_complete':
            setCurrentConversation((prev) => {
              const messages = [...prev.messages];
              messages[messages.length - 1].stage3 = event.data;
              messages[messages.length - 1].loading.stage3 = false;
              return { ...prev, messages };
            });
            break;
          case 'title_complete':
            loadConversations();
            break;
          case 'complete':
            loadConversations();
            setIsLoading(false);
            break;
          case 'error':
            console.error('Stream error:', event.message);
            setIsLoading(false);
            break;
        }
      });
    } catch (error) {
      console.error('Failed to send message:', error);
      setCurrentConversation((prev) => ({
        ...prev,
        messages: prev.messages.slice(0, -2),
      }));
      setIsLoading(false);
    }
  };

  return (
    <div className={`app ${darkMode ? 'dark-mode' : 'light-mode'}`}>
      <Sidebar
        conversations={conversations}
        currentConversationId={currentConversationId}
        onSelectConversation={handleSelectConversation}
        onNewConversation={handleNewConversation}
        onDeleteConversation={handleDeleteConversation}
        onRenameConversation={handleRenameConversation}
        onExportConversation={handleExportConversation}
        darkMode={darkMode}
        onToggleDarkMode={() => setDarkMode(!darkMode)}
      />
      <ChatInterface
        conversation={currentConversation}
        onSendMessage={handleSendMessage}
        isLoading={isLoading}
      />
    </div>
  );
}

export default App;
APPJSX

# App.css
cat > frontend/src/App.css << 'APPCSS'
:root {
  --bg-primary: #0f0f0f;
  --bg-secondary: #1a1a1a;
  --bg-tertiary: #242424;
  --bg-hover: #2a2a2a;
  --text-primary: #ffffff;
  --text-secondary: #a0a0a0;
  --text-muted: #666666;
  --border-color: #333333;
  --accent-primary: #3b82f6;
  --accent-success: #22c55e;
  --accent-warning: #f59e0b;
  --accent-danger: #ef4444;
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --transition-fast: 150ms ease;
}

.light-mode {
  --bg-primary: #ffffff;
  --bg-secondary: #f8f9fa;
  --bg-tertiary: #f1f3f4;
  --bg-hover: #e8eaed;
  --text-primary: #1f1f1f;
  --text-secondary: #5f6368;
  --text-muted: #9aa0a6;
  --border-color: #e0e0e0;
}

* { margin: 0; padding: 0; box-sizing: border-box; }

body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
  background-color: var(--bg-primary);
  color: var(--text-primary);
}

.app {
  display: flex;
  height: 100vh;
  background-color: var(--bg-primary);
}

.spinner {
  width: 20px;
  height: 20px;
  border: 2px solid var(--border-color);
  border-top-color: var(--accent-primary);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin { to { transform: rotate(360deg); } }
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
@keyframes slideIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
APPCSS

# index.css
cat > frontend/src/index.css << 'INDEXCSS'
body { margin: 0; }
INDEXCSS

# main.jsx
cat > frontend/src/main.jsx << 'MAINJSX'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
MAINJSX

# api.js
cat > frontend/src/api.js << 'APIJS'
const API_BASE = 'http://72.60.126.230:8001';

export const api = {
  async listConversations() {
    const response = await fetch(`${API_BASE}/api/conversations`);
    if (!response.ok) throw new Error('Failed to list conversations');
    return response.json();
  },

  async createConversation() {
    const response = await fetch(`${API_BASE}/api/conversations`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    });
    if (!response.ok) throw new Error('Failed to create conversation');
    return response.json();
  },

  async getConversation(id) {
    const response = await fetch(`${API_BASE}/api/conversations/${id}`);
    if (!response.ok) throw new Error('Failed to get conversation');
    return response.json();
  },

  async deleteConversation(id) {
    const response = await fetch(`${API_BASE}/api/conversations/${id}`, { method: 'DELETE' });
    if (!response.ok) throw new Error('Failed to delete conversation');
    return response.json();
  },

  async renameConversation(id, title) {
    const response = await fetch(`${API_BASE}/api/conversations/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title }),
    });
    if (!response.ok) throw new Error('Failed to rename conversation');
    return response.json();
  },

  async exportConversation(id) {
    const response = await fetch(`${API_BASE}/api/conversations/${id}/export`);
    if (!response.ok) throw new Error('Failed to export conversation');
    return response.text();
  },

  async sendMessageStream(conversationId, content, onEvent) {
    const response = await fetch(`${API_BASE}/api/conversations/${conversationId}/message/stream`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ content }),
    });
    if (!response.ok) throw new Error('Failed to send message');

    const reader = response.body.getReader();
    const decoder = new TextDecoder();

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      const chunk = decoder.decode(value);
      const lines = chunk.split('\n');
      for (const line of lines) {
        if (line.startsWith('data: ')) {
          try {
            const event = JSON.parse(line.slice(6));
            onEvent(event.type, event);
          } catch (e) {}
        }
      }
    }
  },
};
APIJS

# Sidebar.jsx
cat > frontend/src/components/Sidebar.jsx << 'SIDEBARJSX'
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
SIDEBARJSX

# Sidebar.css
cat > frontend/src/components/Sidebar.css << 'SIDEBARCSS'
.sidebar {
  width: 300px;
  height: 100vh;
  background-color: var(--bg-secondary);
  border-right: 1px solid var(--border-color);
  display: flex;
  flex-direction: column;
}

.sidebar-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1rem;
  border-bottom: 1px solid var(--border-color);
}

.brand { display: flex; align-items: center; gap: 0.75rem; }
.brand-icon { font-size: 1.5rem; }
.brand-text h1 { font-size: 1rem; font-weight: 700; color: var(--text-primary); }
.brand-tagline { font-size: 0.65rem; color: var(--text-muted); text-transform: uppercase; }

.theme-toggle {
  width: 36px;
  height: 36px;
  border-radius: var(--radius-md);
  background-color: var(--bg-tertiary);
  border: none;
  cursor: pointer;
}

.new-session-btn {
  margin: 1rem;
  padding: 0.75rem;
  background: linear-gradient(135deg, var(--accent-primary), #6366f1);
  color: white;
  font-weight: 600;
  border: none;
  border-radius: var(--radius-md);
  cursor: pointer;
}

.sessions-list { flex: 1; overflow-y: auto; padding: 0.5rem; }

.session-item {
  display: flex;
  align-items: center;
  padding: 0.75rem;
  margin-bottom: 0.25rem;
  border-radius: var(--radius-md);
  cursor: pointer;
  transition: background-color var(--transition-fast);
}

.session-item:hover { background-color: var(--bg-hover); }
.session-item.active { background-color: var(--bg-tertiary); }

.session-content { flex: 1; min-width: 0; }
.session-title { font-size: 0.9rem; color: var(--text-primary); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.session-meta { font-size: 0.75rem; color: var(--text-muted); }

.session-actions { position: relative; }
.session-actions button { background: none; border: none; color: var(--text-muted); cursor: pointer; padding: 0.25rem; }

.action-menu {
  position: absolute;
  right: 0;
  top: 100%;
  background-color: var(--bg-secondary);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-md);
  z-index: 100;
  min-width: 120px;
}

.action-menu button {
  display: block;
  width: 100%;
  padding: 0.5rem 0.75rem;
  text-align: left;
  font-size: 0.85rem;
  color: var(--text-secondary);
}

.action-menu button:hover { background-color: var(--bg-hover); }
.action-menu button.danger:hover { background-color: rgba(239, 68, 68, 0.1); color: var(--accent-danger); }

.rename-input {
  flex: 1;
  padding: 0.375rem;
  background-color: var(--bg-tertiary);
  border: 1px solid var(--accent-primary);
  border-radius: var(--radius-sm);
  color: var(--text-primary);
}

.sidebar-footer {
  padding: 1rem;
  border-top: 1px solid var(--border-color);
  text-align: center;
  font-size: 0.75rem;
  color: var(--text-muted);
}
SIDEBARCSS

# ChatInterface.jsx
cat > frontend/src/components/ChatInterface.jsx << 'CHATJSX'
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
CHATJSX

# ChatInterface.css
cat > frontend/src/components/ChatInterface.css << 'CHATCSS'
.chat-interface {
  flex: 1;
  display: flex;
  flex-direction: column;
  height: 100vh;
  background-color: var(--bg-primary);
}

.messages-container {
  flex: 1;
  overflow-y: auto;
  padding: 2rem;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  text-align: center;
  color: var(--text-secondary);
}

.empty-state h2 { font-size: 1.5rem; color: var(--text-primary); margin-bottom: 0.5rem; }

.message-group { margin-bottom: 1.5rem; animation: slideIn 0.3s ease; }

.message-label { font-weight: 600; font-size: 0.9rem; color: var(--text-primary); margin-bottom: 0.5rem; }

.user-message .message-content {
  background-color: var(--bg-secondary);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-lg);
  padding: 1rem;
  max-width: 80%;
}

.stage-loading {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem;
  background-color: var(--bg-secondary);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-lg);
  margin-bottom: 1rem;
  color: var(--text-secondary);
}

.input-form {
  padding: 1rem 2rem;
  border-top: 1px solid var(--border-color);
  display: flex;
  gap: 0.75rem;
}

.message-input {
  flex: 1;
  padding: 0.75rem;
  background-color: var(--bg-secondary);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-lg);
  color: var(--text-primary);
  font-size: 0.95rem;
  resize: none;
}

.message-input:focus { outline: none; border-color: var(--accent-primary); }

.send-button {
  padding: 0.75rem 1.5rem;
  background: linear-gradient(135deg, var(--accent-primary), #6366f1);
  color: white;
  font-weight: 600;
  border: none;
  border-radius: var(--radius-lg);
  cursor: pointer;
}

.send-button:disabled { opacity: 0.5; cursor: not-allowed; }
CHATCSS

# Stage1.jsx
cat > frontend/src/components/Stage1.jsx << 'STAGE1JSX'
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
STAGE1JSX

# Stage1.css
cat > frontend/src/components/Stage1.css << 'STAGE1CSS'
.stage1 {
  background-color: var(--bg-secondary);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-lg);
  padding: 1rem;
  margin-bottom: 1rem;
}

.stage-title { font-size: 1rem; font-weight: 600; color: var(--text-primary); margin-bottom: 1rem; }

.responses-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 0.75rem; }

.response-card {
  background-color: var(--bg-primary);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-md);
  overflow: hidden;
}

.response-card.expanded { grid-column: 1 / -1; }

.response-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem;
  cursor: pointer;
  background-color: var(--bg-tertiary);
}

.model-name { font-weight: 600; color: var(--text-primary); }
.expand-btn { color: var(--text-muted); }

.response-body { padding: 1rem; font-size: 0.9rem; line-height: 1.6; }
STAGE1CSS

# Stage2.jsx
cat > frontend/src/components/Stage2.jsx << 'STAGE2JSX'
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
STAGE2JSX

# Stage2.css
cat > frontend/src/components/Stage2.css << 'STAGE2CSS'
.stage2 {
  background-color: var(--bg-secondary);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-lg);
  padding: 1rem;
  margin-bottom: 1rem;
}

.stage2 .stage-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem; }
.stage2 .stage-header button { background: var(--bg-tertiary); border: 1px solid var(--border-color); padding: 0.375rem 0.75rem; border-radius: var(--radius-md); color: var(--text-secondary); cursor: pointer; }

.rankings-list { display: flex; flex-direction: column; gap: 0.5rem; }

.ranking-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem;
  background-color: var(--bg-primary);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-md);
}

.ranking-item.rank-1 { border-color: #f59e0b; background: rgba(245, 158, 11, 0.1); }
.ranking-item.rank-2 { border-color: #9ca3af; background: rgba(156, 163, 175, 0.1); }
.ranking-item.rank-3 { border-color: #b45309; background: rgba(180, 83, 9, 0.1); }

.rank-medal { font-size: 1.25rem; }
.rank-model { flex: 1; font-weight: 500; color: var(--text-primary); }
.rank-score { font-size: 0.85rem; color: var(--text-muted); }

.detailed-rankings { margin-top: 1rem; display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 0.75rem; }
.ranking-card { background-color: var(--bg-primary); border: 1px solid var(--border-color); border-radius: var(--radius-md); overflow: hidden; }
.ranking-card-header { padding: 0.5rem 0.75rem; background-color: var(--bg-tertiary); font-weight: 500; font-size: 0.85rem; }
.ranking-card-body { padding: 0.75rem; font-size: 0.8rem; color: var(--text-secondary); max-height: 150px; overflow-y: auto; }
STAGE2CSS

# Stage3.jsx
cat > frontend/src/components/Stage3.jsx << 'STAGE3JSX'
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
STAGE3JSX

# Stage3.css
cat > frontend/src/components/Stage3.css << 'STAGE3CSS'
.stage3 {
  background: linear-gradient(135deg, var(--bg-secondary), rgba(59, 130, 246, 0.05));
  border: 1px solid var(--accent-primary);
  border-radius: var(--radius-lg);
  padding: 1.25rem;
  margin-bottom: 1rem;
}

.stage3 .stage-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem; padding-bottom: 1rem; border-bottom: 1px solid var(--border-color); }
.stage3 .stage-title { font-size: 1.1rem; font-weight: 700; color: var(--text-primary); }

.chairman-badge {
  padding: 0.25rem 0.5rem;
  background: linear-gradient(135deg, var(--accent-primary), #8b5cf6);
  color: white;
  font-size: 0.7rem;
  font-weight: 600;
  text-transform: uppercase;
  border-radius: var(--radius-sm);
}

.final-response {
  background-color: var(--bg-primary);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-md);
  padding: 1.25rem;
  line-height: 1.7;
}

.council-stamp {
  margin-top: 1rem;
  text-align: right;
  color: var(--accent-success);
  font-size: 0.85rem;
  font-weight: 500;
}

.stage3.error { background-color: rgba(239, 68, 68, 0.1); border-color: var(--accent-danger); color: var(--accent-danger); }
STAGE3CSS

# ============================================
# BACKEND FILES
# ============================================

echo "[4/6] Installing backend files..."

# backend/__init__.py
cat > backend/__init__.py << 'BACKENDINIT'
"""The Board Room - XMARCS Strategic Council Backend."""
BACKENDINIT

# backend/council.py - THE COMPLETE NEW VERSION
cat > backend/council.py << 'COUNCILPY'
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
COUNCILPY

# backend/main.py
cat > backend/main.py << 'MAINPY'
"""FastAPI backend for The Board Room - XMARCS Strategic Council."""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, PlainTextResponse
from pydantic import BaseModel
from typing import List, Dict, Any
import uuid
import json
import asyncio

import storage
from council import (
    run_full_council,
    generate_conversation_title,
    stage1_collect_responses,
    stage2_collect_rankings,
    stage3_synthesize_final,
    calculate_aggregate_rankings
)
from config import CORS_ORIGINS

app = FastAPI(title="The Board Room API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class CreateConversationRequest(BaseModel):
    pass


class SendMessageRequest(BaseModel):
    content: str


class UpdateConversationRequest(BaseModel):
    title: str


@app.on_event("startup")
async def startup_event():
    storage.init_db()


@app.get("/")
async def root():
    return {"status": "ok", "service": "The Board Room API", "version": "1.0.0"}


@app.get("/api/conversations")
async def list_conversations():
    return storage.list_conversations()


@app.post("/api/conversations")
async def create_conversation(request: CreateConversationRequest):
    conversation_id = str(uuid.uuid4())
    return storage.create_conversation(conversation_id)


@app.get("/api/conversations/{conversation_id}")
async def get_conversation(conversation_id: str):
    conversation = storage.get_conversation(conversation_id)
    if conversation is None:
        raise HTTPException(status_code=404, detail="Conversation not found")
    return conversation


@app.delete("/api/conversations/{conversation_id}")
async def delete_conversation(conversation_id: str):
    storage.delete_conversation(conversation_id)
    return {"status": "deleted"}


@app.put("/api/conversations/{conversation_id}")
async def update_conversation(conversation_id: str, request: UpdateConversationRequest):
    storage.update_conversation_title(conversation_id, request.title)
    return {"status": "updated"}


@app.get("/api/conversations/{conversation_id}/export")
async def export_conversation(conversation_id: str):
    conversation = storage.get_conversation(conversation_id)
    if conversation is None:
        raise HTTPException(status_code=404, detail="Conversation not found")
    
    md = f"# The Board Room Session\n\n**ID:** {conversation_id[:8]}\n**Title:** {conversation['title']}\n\n---\n\n"
    for msg in conversation['messages']:
        if msg['role'] == 'user':
            md += f"## Your Question\n\n{msg['content']}\n\n"
        else:
            if msg.get('stage3'):
                md += f"## Board Room Decision\n\n{msg['stage3']}\n\n---\n\n"
    return PlainTextResponse(content=md, media_type="text/markdown")


@app.post("/api/conversations/{conversation_id}/message/stream")
async def send_message_stream(conversation_id: str, request: SendMessageRequest):
    conversation = storage.get_conversation(conversation_id)
    if conversation is None:
        raise HTTPException(status_code=404, detail="Conversation not found")

    is_first_message = len(conversation["messages"]) == 0

    async def event_generator():
        try:
            storage.add_user_message(conversation_id, request.content)

            title_task = None
            if is_first_message:
                title_task = asyncio.create_task(generate_conversation_title(request.content))

            yield f"data: {json.dumps({'type': 'stage1_start'})}\n\n"
            stage1_results = await stage1_collect_responses(request.content)
            yield f"data: {json.dumps({'type': 'stage1_complete', 'data': stage1_results})}\n\n"

            yield f"data: {json.dumps({'type': 'stage2_start'})}\n\n"
            stage2_results, label_to_model = await stage2_collect_rankings(request.content, stage1_results)
            aggregate_rankings = calculate_aggregate_rankings(stage2_results, label_to_model)
            yield f"data: {json.dumps({'type': 'stage2_complete', 'data': stage2_results, 'metadata': {'label_to_model': label_to_model, 'aggregate_rankings': aggregate_rankings}})}\n\n"

            yield f"data: {json.dumps({'type': 'stage3_start'})}\n\n"
            stage3_result = await stage3_synthesize_final(request.content, stage1_results, stage2_results)
            yield f"data: {json.dumps({'type': 'stage3_complete', 'data': stage3_result})}\n\n"

            if title_task:
                title = await title_task
                storage.update_conversation_title(conversation_id, title)
                yield f"data: {json.dumps({'type': 'title_complete', 'data': {'title': title}})}\n\n"

            storage.add_assistant_message(conversation_id, stage1_results, stage2_results, stage3_result)
            yield f"data: {json.dumps({'type': 'complete'})}\n\n"

        except Exception as e:
            yield f"data: {json.dumps({'type': 'error', 'message': str(e)})}\n\n"

    return StreamingResponse(event_generator(), media_type="text/event-stream")
MAINPY

# backend/storage.py
cat > backend/storage.py << 'STORAGEPY'
"""PostgreSQL database models and storage."""

from sqlalchemy import create_engine, Column, String, DateTime, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime
from typing import List, Dict, Any, Optional

from config import DATABASE_URL

Base = declarative_base()
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Conversation(Base):
    __tablename__ = "conversations"
    id = Column(String, primary_key=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    title = Column(String, default="New Conversation")
    messages = Column(JSON, default=list)


def init_db():
    Base.metadata.create_all(bind=engine)


def create_conversation(conversation_id: str) -> Dict[str, Any]:
    db = SessionLocal()
    try:
        conversation = Conversation(id=conversation_id, created_at=datetime.utcnow(), title="New Conversation", messages=[])
        db.add(conversation)
        db.commit()
        db.refresh(conversation)
        return {"id": conversation.id, "created_at": conversation.created_at.isoformat(), "title": conversation.title, "messages": conversation.messages}
    finally:
        db.close()


def get_conversation(conversation_id: str) -> Optional[Dict[str, Any]]:
    db = SessionLocal()
    try:
        conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
        if not conversation:
            return None
        return {"id": conversation.id, "created_at": conversation.created_at.isoformat(), "title": conversation.title, "messages": conversation.messages}
    finally:
        db.close()


def list_conversations() -> List[Dict[str, Any]]:
    db = SessionLocal()
    try:
        conversations = db.query(Conversation).order_by(Conversation.created_at.desc()).all()
        return [{"id": conv.id, "created_at": conv.created_at.isoformat(), "title": conv.title, "message_count": len(conv.messages)} for conv in conversations]
    finally:
        db.close()


def add_user_message(conversation_id: str, content: str):
    db = SessionLocal()
    try:
        conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
        if conversation:
            messages = conversation.messages or []
            messages.append({"role": "user", "content": content})
            conversation.messages = messages
            db.commit()
    finally:
        db.close()


def add_assistant_message(conversation_id: str, stage1: List, stage2: List, stage3: str):
    db = SessionLocal()
    try:
        conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
        if conversation:
            messages = conversation.messages or []
            messages.append({"role": "assistant", "stage1": stage1, "stage2": stage2, "stage3": stage3})
            conversation.messages = messages
            db.commit()
    finally:
        db.close()


def update_conversation_title(conversation_id: str, title: str):
    db = SessionLocal()
    try:
        conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
        if conversation:
            conversation.title = title
            db.commit()
    finally:
        db.close()


def delete_conversation(conversation_id: str):
    db = SessionLocal()
    try:
        conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
        if conversation:
            db.delete(conversation)
            db.commit()
    finally:
        db.close()
STORAGEPY

# backend/llm_clients/__init__.py
cat > backend/llm_clients/__init__.py << 'LLMINIT'
"""LLM client modules for The Board Room."""

import asyncio
from typing import List, Dict, Any, Optional

from .anthropic_client import query_claude
from .openai_client import query_gpt
from .google_client import query_gemini
from .xai_client import query_grok
from .zhipu_client import query_glm


async def query_model(
    provider: str,
    model_id: str,
    messages: List[Dict[str, str]],
    timeout: float = 180.0
) -> Optional[Dict[str, Any]]:
    """Query a single model."""
    if provider == "anthropic":
        return await query_claude(model_id, messages, timeout)
    elif provider == "openai":
        return await query_gpt(model_id, messages, timeout)
    elif provider == "google":
        return await query_gemini(model_id, messages, timeout)
    elif provider == "xai":
        return await query_grok(model_id, messages, timeout)
    elif provider == "zhipu":
        return await query_glm(model_id, messages, timeout)
    else:
        return None


async def query_models_parallel(
    models: List[Dict[str, str]],
    messages: List[Dict[str, str]],
    timeout: float = 180.0
) -> Dict[str, Dict[str, Any]]:
    """Query multiple models in parallel."""
    tasks = []
    model_names = []
    
    for model_config in models:
        task = query_model(model_config['provider'], model_config['model_id'], messages, timeout)
        tasks.append(task)
        model_names.append(model_config['name'])
    
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    return {name: result for name, result in zip(model_names, results) if not isinstance(result, Exception) and result is not None}
LLMINIT

# backend/llm_clients/anthropic_client.py
cat > backend/llm_clients/anthropic_client.py << 'ANTHROPICPY'
"""Anthropic (Claude) API client."""

import httpx
from typing import List, Dict, Any, Optional
from ..config import ANTHROPIC_API_KEY, ANTHROPIC_API_URL

MAX_OUTPUT_TOKENS = 16384


async def query_claude(model_id: str, messages: List[Dict[str, str]], timeout: float = 180.0) -> Optional[Dict[str, Any]]:
    headers = {"x-api-key": ANTHROPIC_API_KEY, "anthropic-version": "2023-06-01", "Content-Type": "application/json"}
    
    system_msg = None
    chat_messages = []
    for msg in messages:
        if msg["role"] == "system":
            system_msg = msg["content"]
        else:
            chat_messages.append(msg)
    
    payload = {"model": model_id, "max_tokens": MAX_OUTPUT_TOKENS, "messages": chat_messages}
    if system_msg:
        payload["system"] = system_msg

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.post(ANTHROPIC_API_URL, headers=headers, json=payload)
            response.raise_for_status()
            data = response.json()
            usage = data.get('usage', {})
            return {
                'content': data['content'][0]['text'],
                'usage': {'prompt_tokens': usage.get('input_tokens', 0), 'completion_tokens': usage.get('output_tokens', 0), 'total_tokens': usage.get('input_tokens', 0) + usage.get('output_tokens', 0), 'max_tokens': MAX_OUTPUT_TOKENS}
            }
    except Exception as e:
        print(f"Error querying Claude {model_id}: {e}")
        return None
ANTHROPICPY

# backend/llm_clients/openai_client.py
cat > backend/llm_clients/openai_client.py << 'OPENAIPY'
"""OpenAI (GPT-4) API client."""

import httpx
from typing import List, Dict, Any, Optional
from ..config import OPENAI_API_KEY, OPENAI_API_URL

MAX_OUTPUT_TOKENS = 16384


async def query_gpt(model_id: str, messages: List[Dict[str, str]], timeout: float = 180.0) -> Optional[Dict[str, Any]]:
    headers = {"Authorization": f"Bearer {OPENAI_API_KEY}", "Content-Type": "application/json"}
    payload = {"model": model_id, "messages": messages, "max_tokens": MAX_OUTPUT_TOKENS, "temperature": 0.3}

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.post(OPENAI_API_URL, headers=headers, json=payload)
            response.raise_for_status()
            data = response.json()
            usage = data.get('usage', {})
            return {
                'content': data['choices'][0]['message']['content'],
                'usage': {'prompt_tokens': usage.get('prompt_tokens', 0), 'completion_tokens': usage.get('completion_tokens', 0), 'total_tokens': usage.get('total_tokens', 0), 'max_tokens': MAX_OUTPUT_TOKENS}
            }
    except Exception as e:
        print(f"Error querying GPT {model_id}: {e}")
        return None
OPENAIPY

# backend/llm_clients/google_client.py
cat > backend/llm_clients/google_client.py << 'GOOGLEPY'
"""Google (Gemini) API client."""

import httpx
from typing import List, Dict, Any, Optional
from ..config import GOOGLE_API_KEY, GOOGLE_API_URL

MAX_OUTPUT_TOKENS = 8192


async def query_gemini(model_id: str, messages: List[Dict[str, str]], timeout: float = 180.0) -> Optional[Dict[str, Any]]:
    gemini_parts = []
    for msg in messages:
        gemini_parts.append({"text": msg["content"]})

    payload = {"contents": [{"parts": gemini_parts}], "generationConfig": {"temperature": 0.3, "maxOutputTokens": MAX_OUTPUT_TOKENS}}
    url = f"{GOOGLE_API_URL}/{model_id}:generateContent?key={GOOGLE_API_KEY}"

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.post(url, headers={"Content-Type": "application/json"}, json=payload)
            response.raise_for_status()
            data = response.json()
            usage = data.get('usageMetadata', {})
            return {
                'content': data['candidates'][0]['content']['parts'][0]['text'],
                'usage': {'prompt_tokens': usage.get('promptTokenCount', 0), 'completion_tokens': usage.get('candidatesTokenCount', 0), 'total_tokens': usage.get('totalTokenCount', 0), 'max_tokens': MAX_OUTPUT_TOKENS}
            }
    except Exception as e:
        print(f"Error querying Gemini {model_id}: {e}")
        return None
GOOGLEPY

# backend/llm_clients/xai_client.py
cat > backend/llm_clients/xai_client.py << 'XAIPY'
"""xAI (Grok) API client."""

import httpx
from typing import List, Dict, Any, Optional
from ..config import XAI_API_KEY, XAI_API_URL

MAX_OUTPUT_TOKENS = 16384


async def query_grok(model_id: str, messages: List[Dict[str, str]], timeout: float = 180.0) -> Optional[Dict[str, Any]]:
    headers = {"Authorization": f"Bearer {XAI_API_KEY}", "Content-Type": "application/json"}
    payload = {"model": model_id, "messages": messages, "max_tokens": MAX_OUTPUT_TOKENS, "temperature": 0.3}

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.post(XAI_API_URL, headers=headers, json=payload)
            response.raise_for_status()
            data = response.json()
            usage = data.get('usage', {})
            return {
                'content': data['choices'][0]['message']['content'],
                'usage': {'prompt_tokens': usage.get('prompt_tokens', 0), 'completion_tokens': usage.get('completion_tokens', 0), 'total_tokens': usage.get('total_tokens', 0), 'max_tokens': MAX_OUTPUT_TOKENS}
            }
    except Exception as e:
        print(f"Error querying Grok {model_id}: {e}")
        return None
XAIPY

# backend/llm_clients/zhipu_client.py
cat > backend/llm_clients/zhipu_client.py << 'ZHIPUPY'
"""Zhipu AI (GLM-4) API client."""

import httpx
from typing import List, Dict, Any, Optional
from ..config import ZHIPU_API_KEY, ZHIPU_API_URL

MAX_OUTPUT_TOKENS = 16384


async def query_glm(model_id: str, messages: List[Dict[str, str]], timeout: float = 180.0) -> Optional[Dict[str, Any]]:
    headers = {"Authorization": f"Bearer {ZHIPU_API_KEY}", "Content-Type": "application/json"}
    payload = {"model": model_id, "messages": messages, "max_tokens": MAX_OUTPUT_TOKENS, "temperature": 0.2}

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.post(ZHIPU_API_URL, headers=headers, json=payload)
            response.raise_for_status()
            data = response.json()
            usage = data.get('usage', {})
            return {
                'content': data['choices'][0]['message']['content'],
                'usage': {'prompt_tokens': usage.get('prompt_tokens', 0), 'completion_tokens': usage.get('completion_tokens', 0), 'total_tokens': usage.get('total_tokens', 0), 'max_tokens': MAX_OUTPUT_TOKENS}
            }
    except Exception as e:
        print(f"Error querying GLM {model_id}: {e}")
        return None
ZHIPUPY

# ============================================
# COMMIT AND PUSH
# ============================================

echo "[5/6] Committing to git..."
git add -A
git commit -m "The Board Room Executive Edition: Professional research tool, zero hand-holding, 16K token limits"

echo "[6/6] Pushing to origin..."
git push origin master

echo ""
echo "============================================"
echo "DEPLOYMENT COMPLETE"
echo "============================================"
echo ""
echo "Next steps:"
echo "1. Go to Dokploy and redeploy the application"
echo "2. Or restart Docker containers manually:"
echo "   docker-compose down && docker-compose up -d --build"
echo ""
echo "The Board Room is ready."
