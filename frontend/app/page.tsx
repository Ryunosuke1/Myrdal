import { Separator } from "@/components/ui/separator";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { ArrowRight, Brain, FileText, Github, Globe, Send, Terminal } from "lucide-react";
import { Hero } from "@/components/Hero";
export default function Home() {
  return (
    <main className="nordic-container pb-20">
      <div className="flex flex-col gap-8 items-center w-full">
        <Hero />
        
        {/* Nordic風ヘッダーとテキスト入力フィールド */}
        <section className="w-full max-w-3xl mx-auto">
          <div className="nordic-card p-6 md:p-8">
            <h2 className="text-2xl md:text-3xl font-bold mb-6 text-center nordic-font text-primary">
              What can Myrdal help you with?
            </h2>
            
            <div className="rounded-lg border border-input bg-background p-3 shadow-sm focus-within:ring-2 focus-within:ring-primary">
              <textarea 
                className="w-full min-h-[120px] resize-y bg-transparent text-base outline-none placeholder:text-muted-foreground"
                placeholder="AI エージェントに質問や指示を入力してください..."
              />
              <div className="flex justify-end mt-2">
                <button className="vy-button flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-md hover:bg-primary/90 transition-colors">
                  <span>送信</span>
                  <Send className="h-4 w-4" />
                </button>
              </div>
            </div>
            
            <p className="mt-6 text-sm text-muted-foreground nordic-font">
              Myrdalは、あなたの質問に答えたり、タスクを実行したりするAIエージェントです。
              コードの作成、ウェブの検索、データ分析など、さまざまなタスクを自律的に処理できます。
            </p>
          </div>
        </section>
        
        <Separator className="w-full my-10 opacity-30" />
        
        {/* 既存のセクション */}
        <section className="w-full max-w-5xl mx-auto">
          <h2 className="text-2xl md:text-3xl font-semibold mb-8 text-center">
            <span className="text-primary">Myrdal</span> の特徴
          </h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[
              {
                title: "オンチェーンAI",
                description: "AIの判断とアクションがブロックチェーン上に記録され、透明性が保証されます",
                icon: <Brain className="text-primary h-8 w-8" />
              },
              {
                title: "自律エージェント",
                description: "複雑なタスクを自律的に実行し、スマートコントラクトと連携します",
                icon: <Terminal className="text-primary h-8 w-8" />
              },
              {
                title: "Linea対応",
                description: "高速で低コストのLineaネットワーク上で動作します",
                icon: <Globe className="text-primary h-8 w-8" />
              },
            ].map((feature, index) => (
              <div key={index} className="nordic-card p-6 flex flex-col">
                <div className="mb-4">{feature.icon}</div>
                <h3 className="text-xl font-medium mb-2">{feature.title}</h3>
                <p className="text-muted-foreground">{feature.description}</p>
              </div>
            ))}
          </div>
        </section>
        
        <section className="mt-16 w-full max-w-5xl mx-auto">
          <h2 className="text-2xl md:text-3xl font-semibold mb-8 text-center">
            <span className="text-primary">活用</span>シナリオ
          </h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Card className="nordic-card border-none overflow-hidden">
              <div className="wood-texture h-2"></div>
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-xl">
                  <FileText className="h-5 w-5 text-secondary" />
                  ドキュメント
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-muted-foreground">
                  Myrdalの詳細な使い方とAPIドキュメントをご覧ください。
                </p>
                <a
                  href="https://github.com/yourusername/myrdal/docs"
                  target="_blank"
                  className="flex items-center gap-2 text-primary hover:underline"
                >
                  <span>ドキュメントを見る</span>
                  <ArrowRight className="h-4 w-4" />
                </a>
              </CardContent>
            </Card>
            
            <Card className="nordic-card border-none overflow-hidden">
              <div className="wood-texture h-2"></div>
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-xl">
                  <Github className="h-5 w-5 text-secondary" />
                  開発リソース
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-muted-foreground">
                  オープンソースのMyrdalプロジェクトに貢献しましょう。
                </p>
                <a
                  href="https://github.com/yourusername/myrdal"
                  target="_blank"
                  className="flex items-center gap-2 text-primary hover:underline"
                >
                  <span>GitHubリポジトリ</span>
                  <ArrowRight className="h-4 w-4" />
                </a>
              </CardContent>
            </Card>
          </div>
        </section>
        
        <section className="mt-16 w-full max-w-3xl mx-auto text-center">
          <div className="rounded-lg bg-gradient-to-r from-primary/10 to-secondary/10 p-8 border border-muted">
            <h2 className="text-2xl font-medium mb-4">Myrdalを今すぐ使ってみる</h2>
            <p className="text-muted-foreground mb-6">
              ウォレットを接続して、オンチェーンAIエージェントの可能性を体験しましょう
            </p>
            <div className="inline-flex items-center gap-2 px-6 py-3 bg-primary text-white rounded-md hover:bg-primary/90 transition-colors">
              始める
              <ArrowRight className="h-4 w-4" />
            </div>
          </div>
        </section>
      </div>
    </main>
  );
}
