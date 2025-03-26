import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import Chat from "@/components/chat/Chat"
import ChatHistory from "@/components/chat/ChatHistory"

export default function ChatPage() {
  return (
    <div className="nordic-container pb-20">
      <div className="max-w-5xl mx-auto pt-6 px-4">
        <div className="nordic-card p-6 md:p-8 overflow-hidden">
          <h1 className="text-2xl md:text-3xl font-bold mb-6 text-center nordic-font text-primary">
            Myrdal チャットアシスタント
          </h1>
          
          <Tabs defaultValue="new" className="w-full">
            <div className="flex justify-center mb-6">
              <TabsList className="vy-tabs-list">
                <TabsTrigger value="new" className="vy-tab">新規チャット</TabsTrigger>
                <TabsTrigger value="history" className="vy-tab">履歴</TabsTrigger>
              </TabsList>
            </div>
            
            <TabsContent value="new" className="mt-0">
              <Chat />
            </TabsContent>
            
            <TabsContent value="history" className="mt-0">
              <ChatHistory />
            </TabsContent>
          </Tabs>
          
          <p className="mt-6 text-sm text-muted-foreground nordic-font text-center">
            Myrdalエージェントはあなたの質問に答え、タスクを実行します。
            チャット履歴は暗号化されてブロックチェーン上に保存されます。
          </p>
        </div>
      </div>
    </div>
  );
}