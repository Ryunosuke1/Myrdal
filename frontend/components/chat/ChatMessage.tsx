"use client";

import { cn } from "@/lib/utils";
import { Brain, User } from "lucide-react";
import { ReactNode } from "react";

export type MessageRole = "user" | "agent";

export interface Message {
  id: string;
  content: string;
  role: MessageRole;
  timestamp: Date;
}

interface ChatMessageProps {
  message: Message;
  isLast?: boolean;
}

export function ChatMessage({ message, isLast = false }: ChatMessageProps) {
  const isUser = message.role === "user";

  return (
    <div 
      className={cn(
        "flex w-full items-start gap-4 py-4",
        isLast && "pb-1",
        isUser ? "justify-end" : "justify-start"
      )}
    >
      {!isUser && (
        <div className="flex h-8 w-8 shrink-0 select-none items-center justify-center rounded-md border bg-primary text-primary-foreground shadow-sm">
          <Brain className="h-4 w-4" />
        </div>
      )}

      <div 
        className={cn(
          "flex flex-col space-y-1 max-w-[80%]",
          isUser ? "items-end" : "items-start"
        )}
      >
        <div 
          className={cn(
            "px-4 py-3 rounded-lg text-sm",
            isUser 
              ? "bg-primary text-primary-foreground" 
              : "bg-muted text-foreground border border-border"
          )}
        >
          {message.content}
        </div>
        <span className="text-xs text-muted-foreground px-1">
          {formatTime(message.timestamp)}
        </span>
      </div>

      {isUser && (
        <div className="flex h-8 w-8 shrink-0 select-none items-center justify-center rounded-md border bg-background shadow-sm">
          <User className="h-4 w-4" />
        </div>
      )}
    </div>
  );
}

// 時間をフォーマットする関数
function formatTime(date: Date): string {
  return date.toLocaleTimeString('ja-JP', { 
    hour: '2-digit', 
    minute: '2-digit'
  });
}