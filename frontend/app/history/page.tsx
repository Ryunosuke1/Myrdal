import { ChatHistory } from "@/components/chat/ChatHistory";

export default function HistoryPage() {
  return (
    <div className="nordic-container py-10">
      <h1 className="text-3xl font-semibold mb-6 text-center text-primary">チャット履歴</h1>
      <ChatHistory />
    </div>
  );
}