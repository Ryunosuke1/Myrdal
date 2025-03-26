"use client";

import { useState, useRef, useEffect } from "react";
import { Message, ChatMessage } from "./ChatMessage";
import { Button } from "@/components/ui/button";
import { useAccount } from "wagmi";
import { Send, Loader2 } from "lucide-react";
import { generateId } from "@/lib/utils";

export function Chat() {
  const { address, isConnected } = useAccount();
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState<string>("");
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  
  // スクロールを最下部に移動する関数
  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };
  
  // 新しいメッセージが追加されたら自動スクロール
  useEffect(() => {
    scrollToBottom();
  }, [messages]);
  
  // 初期メッセージとしてAIエージェントからの挨拶を表示
  useEffect(() => {
    if (isConnected && messages.length === 0) {
      setMessages([
        {
          id: generateId(),
          role: "agent",
          content: "こんにちは！Myrdalエージェントです。オンチェーン上であなたのタスクをお手伝いします。どのようなことをお手伝いできますか？",
          timestamp: new Date()
        }
      ]);
    }
  }, [isConnected, messages.length]);
  
  // メッセージを送信する関数
  const sendMessage = async () => {
    if (!input.trim() || !isConnected) return;
    
    // ユーザーメッセージを追加
    const userMessage: Message = {
      id: generateId(),
      role: "user",
      content: input,
      timestamp: new Date()
    };
    
    setMessages(prev => [...prev, userMessage]);
    setInput("");
    setIsLoading(true);
    
    try {
      // 実際の実装では、ここでバックエンドAPIやスマートコントラクトと通信
      // 現在はモックレスポンスを使用
      setTimeout(() => {
        const agentMessage: Message = {
          id: generateId(),
          role: "agent",
          content: getAgentResponse(input),
          timestamp: new Date()
        };
        setMessages(prev => [...prev, agentMessage]);
        setIsLoading(false);
      }, 1500);
    } catch (error) {
      console.error("Error sending message:", error);
      setIsLoading(false);
    }
  };
  
  // モックレスポンスを生成する関数（実際の実装ではスマートコントラクトやAPIから取得）
  const getAgentResponse = (userInput: string): string => {
    const input = userInput.toLowerCase();
    
    if (input.includes("こんにちは") || input.includes("はじめまして")) {
      return `こんにちは、${address?.slice(0, 6)}...さん！何かお手伝いできることはありますか？`;
    }
    
    if (input.includes("天気")) {
      return "申し訳ありませんが、現在の実装では天気情報の取得はできません。将来的には外部データソースと連携して、天気情報も提供できるようになる予定です。";
    }
    
    if (input.includes("スマートコントラクト") || input.includes("コード")) {
      return "スマートコントラクトのコード生成や分析のお手伝いができます。具体的にどのようなコントラクトが必要ですか？";
    }
    
    return "ご質問ありがとうございます。Myrdalエージェントは現在開発中のため、限られた応答しかできません。今後のアップデートで、より多くのタスクに対応できるようになります。";
  };
  
  return (
    <div className="flex flex-col h-[calc(100vh-13rem)] max-w-4xl mx-auto w-full overflow-hidden">
      {/* チャットメッセージ表示エリア */}
      <div className="flex-1 overflow-y-auto p-4 space-y-2">
        {messages.map((message, index) => (
          <ChatMessage 
            key={message.id} 
            message={message} 
            isLast={index === messages.length - 1} 
          />
        ))}
        {isLoading && (
          <div className="flex justify-start p-4">
            <div className="bg-muted px-4 py-3 rounded-lg flex items-center space-x-2 border border-border">
              <Loader2 className="h-4 w-4 animate-spin text-primary" />
              <span className="text-sm text-muted-foreground">Myrdalエージェントが考えています...</span>
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>
      
      {/* メッセージ入力エリア */}
      <div className="p-4 border-t border-border bg-card/50">
        {isConnected ? (
          <form 
            onSubmit={(e) => {
              e.preventDefault();
              sendMessage();
            }}
            className="flex items-center gap-2"
          >
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="メッセージを入力..."
              className="flex-1 rounded-md border border-input bg-background px-4 py-2 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
              disabled={isLoading}
            />
            <Button 
              type="submit" 
              size="sm" 
              disabled={!input.trim() || isLoading}
            >
              {isLoading ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <>
                  送信
                  <Send className="h-4 w-4" />
                </>
              )}
            </Button>
          </form>
        ) : (
          <div className="text-center py-4 text-muted-foreground">
            ウォレットを接続してチャットを開始してください
          </div>
        )}
      </div>
    </div>
  );
}