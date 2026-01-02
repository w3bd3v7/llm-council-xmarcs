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
