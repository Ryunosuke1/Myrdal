"use client";

import { useState, useEffect } from "react";
import { useAccount } from "wagmi";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Message } from "./ChatMessage";
import { generateId } from "@/lib/utils";

export function ChatHistory() {
  const { address, isConnected } = useAccount();
  const [history, setHistory] = useState<Message[]>([]);

  useEffect(() => {
    if (isConnected) {
      // ダミーデータを使用してチャット履歴を設定
      setHistory([
        {
          id: generateId(),
          role: "user",
          content: "こんにちは、Myrdalエージェント！",
          timestamp: new Date(Date.now() - 1000 * 60 * 60), // 1時間前
        },
        {
          id: generateId(),
          role: "agent",
          content: "こんにちは！何かお手伝いできることはありますか？",
          timestamp: new Date(Date.now() - 1000 * 60 * 55), // 55分前
        },
        {
          id: generateId(),
          role: "user",
          content: "スマートコントラクトのデプロイ方法を教えてください。",
          timestamp: new Date(Date.now() - 1000 * 60 * 30), // 30分前
        },
        {
          id: generateId(),
          role: "agent",
          content: "もちろんです。まず、Remixを使用してコントラクトをコンパイルし...",
          timestamp: new Date(Date.now() - 1000 * 60 * 25), // 25分前
        },
      ]);
    }
  }, [isConnected]);

  return (
    <div className="space-y-4">
      {history.length > 0 ? (
        history.map((message) => (
          <Card key={message.id} className="nordic-card">
            <CardHeader>
              <CardTitle className="text-lg">
                {message.role === "user" ? "あなた" : "Myrdalエージェント"}
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground">{message.content}</p>
              <span className="text-xs text-muted-foreground">
                {message.timestamp.toLocaleString("ja-JP", {
                  year: "numeric",
                  month: "2-digit",
                  day: "2-digit",
                  hour: "2-digit",
                  minute: "2-digit",
                })}
              </span>
            </CardContent>
          </Card>
        ))
      ) : (
        <p className="text-center text-muted-foreground">チャット履歴がありません。</p>
      )}
    </div>
  );
}