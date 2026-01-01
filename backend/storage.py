"""PostgreSQL database models and storage."""

from sqlalchemy import create_engine, Column, String, DateTime, Text, JSON, Integer
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime
from typing import List, Dict, Any, Optional
import json

from .config import DATABASE_URL

Base = declarative_base()
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Conversation(Base):
    """Conversation model."""
    __tablename__ = "conversations"

    id = Column(String, primary_key=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    title = Column(String, default="New Conversation")
    messages = Column(JSON, default=list)


def init_db():
    """Initialize database tables."""
    Base.metadata.create_all(bind=engine)


def get_db():
    """Get database session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def create_conversation(conversation_id: str) -> Dict[str, Any]:
    """Create a new conversation."""
    db = SessionLocal()
    try:
        conversation = Conversation(
            id=conversation_id,
            created_at=datetime.utcnow(),
            title="New Conversation",
            messages=[]
        )
        db.add(conversation)
        db.commit()
        db.refresh(conversation)
        
        return {
            "id": conversation.id,
            "created_at": conversation.created_at.isoformat(),
            "title": conversation.title,
            "messages": conversation.messages
        }
    finally:
        db.close()


def get_conversation(conversation_id: str) -> Optional[Dict[str, Any]]:
    """Get a conversation by ID."""
    db = SessionLocal()
    try:
        conversation = db.query(Conversation).filter(
            Conversation.id == conversation_id
        ).first()
        
        if not conversation:
            return None
        
        return {
            "id": conversation.id,
            "created_at": conversation.created_at.isoformat(),
            "title": conversation.title,
            "messages": conversation.messages
        }
    finally:
        db.close()


def list_conversations() -> List[Dict[str, Any]]:
    """List all conversations (metadata only)."""
    db = SessionLocal()
    try:
        conversations = db.query(Conversation).order_by(
            Conversation.created_at.desc()
        ).all()
        
        return [
            {
                "id": conv.id,
                "created_at": conv.created_at.isoformat(),
                "title": conv.title,
                "message_count": len(conv.messages)
            }
            for conv in conversations
        ]
    finally:
        db.close()


def add_user_message(conversation_id: str, content: str):
    """Add a user message to a conversation."""
    db = SessionLocal()
    try:
        conversation = db.query(Conversation).filter(
            Conversation.id == conversation_id
        ).first()
        
        if not conversation:
            raise ValueError(f"Conversation {conversation_id} not found")
        
        messages = conversation.messages or []
        messages.append({
            "role": "user",
            "content": content
        })
        conversation.messages = messages
        db.commit()
    finally:
        db.close()


def add_assistant_message(
    conversation_id: str,
    stage1: List[Dict[str, Any]],
    stage2: List[Dict[str, Any]],
    stage3: Dict[str, Any]
):
    """Add an assistant message with all 3 stages."""
    db = SessionLocal()
    try:
        conversation = db.query(Conversation).filter(
            Conversation.id == conversation_id
        ).first()
        
        if not conversation:
            raise ValueError(f"Conversation {conversation_id} not found")
        
        messages = conversation.messages or []
        messages.append({
            "role": "assistant",
            "stage1": stage1,
            "stage2": stage2,
            "stage3": stage3
        })
        conversation.messages = messages
        db.commit()
    finally:
        db.close()


def update_conversation_title(conversation_id: str, title: str):
    """Update conversation title."""
    db = SessionLocal()
    try:
        conversation = db.query(Conversation).filter(
            Conversation.id == conversation_id
        ).first()
        
        if not conversation:
            raise ValueError(f"Conversation {conversation_id} not found")
        
        conversation.title = title
        db.commit()
    finally:
        db.close()
