"use client";
import Image from "next/image";
import { useAccount } from "wagmi";
import { useEffect, useRef, useState } from "react";

export const Hero = () => {
  const { isConnected } = useAccount();
  const [scrollY, setScrollY] = useState(0);
  const heroRef = useRef<HTMLElement>(null);
  
  // スクロール位置を監視してアニメーション用の状態を更新
  useEffect(() => {
    const handleScroll = () => {
      setScrollY(window.scrollY);
    };
    
    window.addEventListener("scroll", handleScroll);
    return () => {
      window.removeEventListener("scroll", handleScroll);
    };
  }, []);
  
  if (isConnected) {
    return (
      <section ref={heroRef} className="relative flex flex-col items-center text-center pt-16 pb-32 overflow-hidden">
        {/* 背景装飾 */}
        <div className="absolute -z-10 opacity-20 top-10 right-0 md:right-10 vy-animate-breathe">
          <div className="w-56 h-56 rounded-full bg-secondary/30 blur-3xl"></div>
        </div>
        <div className="absolute -z-10 opacity-20 -bottom-10 left-0 md:left-10 vy-animate-breathe" style={{ animationDelay: "2s" }}>
          <div className="w-56 h-56 rounded-full bg-primary/30 blur-3xl"></div>
        </div>
        
        {/* 浮遊する装飾要素 */}
        <div className="absolute top-40 right-10 hidden md:block vy-animate-wave" style={{ animationDelay: "1s" }}>
          <Image
            src="/window.svg"
            alt="Window"
            width={80}
            height={80}
            className="opacity-30 rotate-12"
          />
        </div>
        <div className="absolute bottom-40 left-10 hidden md:block vy-animate-wave" style={{ animationDelay: "3s" }}>
          <Image
            src="/file.svg"
            alt="File"
            width={60}
            height={60}
            className="opacity-30 -rotate-12"
          />
        </div>
        
        {/* メインコンテンツ */}
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 vy-animate-fade-in">
          <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold text-foreground mb-6 tracking-tight">
            <span className="bg-clip-text text-transparent bg-gradient-to-r from-primary to-secondary">
              Myrdal AI Agent
            </span>
          </h1>
          <p className="text-muted-foreground text-lg md:text-xl max-w-2xl mx-auto mb-10">
            オンチェーン上であなたの代わりにタスクを実行する汎用AIエージェント。スマートコントラクトと連携して自律的に活動します。
          </p>
          
          <div className="flex items-center justify-center gap-4 flex-wrap mb-12">
            <div className="flex items-center gap-1 px-4 py-2 rounded-lg bg-muted text-muted-foreground shadow-sm vy-animate-slide-right" style={{ animationDelay: "0.2s" }}>
              <div className="w-2 h-2 rounded-full bg-green-500"></div>
              <span>ウォレット接続済み</span>
            </div>
            <div className="px-4 py-2 rounded-lg bg-muted text-muted-foreground flex items-center gap-2 shadow-sm vy-animate-slide-left" style={{ animationDelay: "0.4s" }}>
              <Image
                src="/globe.svg"
                alt="Network"
                width={16}
                height={16}
                className="opacity-70"
              />
              <span>Lineaネットワーク</span>
            </div>
          </div>
          
          <div className="flex flex-col md:flex-row justify-center gap-6 vy-animate-fade-in" style={{ animationDelay: "0.6s" }}>
            <a 
              href="/chat" 
              className="inline-block py-3 px-8 rounded-lg bg-gradient-to-r from-primary to-primary/90 text-white font-medium shadow-md hover:shadow-lg transition-all hover:-translate-y-1"
            >
              チャットを始める
            </a>
            <a 
              href="/history" 
              className="inline-block py-3 px-8 rounded-lg bg-white border border-gray-200 text-gray-800 font-medium shadow-sm hover:shadow-md transition-all hover:-translate-y-1"
            >
              履歴を見る
            </a>
          </div>
        </div>
        
        {/* 波のアニメーション */}
        <div className="absolute bottom-0 left-0 w-full">
          <div className="vy-wave-container">
            <div className="vy-wave"></div>
            <div className="vy-wave"></div>
            <div className="vy-wave"></div>
          </div>
        </div>
      </section>
    );
  }
  
  return (
    <section ref={heroRef} className="relative flex flex-col items-center text-center pt-16 pb-32 overflow-hidden">
      {/* 背景装飾 */}
      <div className="absolute -z-10 opacity-20 top-10 right-0 md:right-10 vy-animate-breathe">
        <div className="w-56 h-56 rounded-full bg-secondary/30 blur-3xl"></div>
      </div>
      <div className="absolute -z-10 opacity-20 -bottom-10 left-0 md:left-10 vy-animate-breathe" style={{ animationDelay: "2s" }}>
        <div className="w-56 h-56 rounded-full bg-primary/30 blur-3xl"></div>
      </div>
      
      {/* 浮遊する装飾要素 */}
      <div className="absolute top-40 right-10 hidden md:block vy-animate-wave" style={{ animationDelay: "1s" }}>
        <Image
          src="/window.svg"
          alt="Window"
          width={80}
          height={80}
          className="opacity-30 rotate-12"
        />
      </div>
      <div className="absolute bottom-40 left-10 hidden md:block vy-animate-wave" style={{ animationDelay: "3s" }}>
        <Image
          src="/file.svg"
          alt="File"
          width={60}
          height={60}
          className="opacity-30 -rotate-12"
        />
      </div>
      
      {/* メインコンテンツ */}
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 vy-animate-fade-in">
        <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold text-foreground mb-6 tracking-tight">
          <span className="bg-clip-text text-transparent bg-gradient-to-r from-primary to-secondary">
            Myrdal AI Agent
          </span>
        </h1>
        <p className="text-muted-foreground text-lg md:text-xl max-w-2xl mx-auto mb-12">
          オンチェーン上であなたの代わりにタスクを実行する汎用AIエージェント。スマートコントラクトと連携して自律的に活動します。
        </p>
      
        <div className="mt-10 flex flex-col items-center vy-animate-fade-in" style={{ animationDelay: "0.4s" }}>
          <div className="w-16 h-16 opacity-70 vy-animate-wave">
            <svg width="64" height="64" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M12 5V19M12 19L19 12M12 19L5 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
          <p className="text-muted-foreground">下のボタンからウォレットを接続してください</p>
        </div>
      </div>
      
      {/* 波のアニメーション */}
      <div className="absolute bottom-0 left-0 w-full">
        <div className="vy-wave-container">
          <div className="vy-wave"></div>
          <div className="vy-wave"></div>
          <div className="vy-wave"></div>
        </div>
      </div>
    </section>
  );
};
