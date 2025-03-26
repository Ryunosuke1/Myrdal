"use client";
import Link from "next/link";
import Image from "next/image";
import { useAccount, useConnect, useDisconnect, useSwitchChain } from "wagmi";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { formatAddress } from "@/lib/utils";
import { ChevronDown, MessageSquare, History, Menu, X } from "lucide-react";
import { useState, useEffect } from "react";

export function Navbar() {
  const { address, isConnected, chain } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();
  const { switchChain, chains } = useSwitchChain();
  const connector = connectors[0];
  const [scrolled, setScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  
  // スクロールを検出してナビゲーションの背景を変更
  useEffect(() => {
    const handleScroll = () => {
      const isScrolled = window.scrollY > 10;
      if (isScrolled !== scrolled) {
        setScrolled(isScrolled);
      }
    };
    
    window.addEventListener("scroll", handleScroll);
    return () => {
      window.removeEventListener("scroll", handleScroll);
    };
  }, [scrolled]);
  
  return (
    <nav 
      className={`fixed top-0 left-0 w-full z-50 transition-all duration-300 vy-animate-fade-in ${
        scrolled ? "bg-white/90 backdrop-blur-sm shadow-sm" : "bg-transparent"
      }`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center py-4">
          {/* ロゴ */}
          <div className="flex items-center">
            <Link href="/" className="flex items-center gap-2">
              <Image
                src="/myrdal-logo.svg"
                alt="Myrdal Logo"
                width={150}
                height={50}
                priority
                className="h-10 w-auto"
              />
            </Link>
          </div>
          
          {/* デスクトップメニュー */}
          <div className="hidden md:flex items-center gap-8">
            <Link 
              href="/chat" 
              className="flex items-center gap-2 text-foreground hover:text-primary transition-colors duration-200 font-medium"
            >
              <MessageSquare className="h-5 w-5" />
              <span>チャット</span>
            </Link>
            <Link 
              href="/history" 
              className="flex items-center gap-2 text-foreground hover:text-primary transition-colors duration-200 font-medium"
            >
              <History className="h-5 w-5" />
              <span>履歴</span>
            </Link>
          </div>
          
          {/* ウォレット接続ボタン */}
          <div className="hidden md:block">
            {isConnected ? (
              <div className="flex items-center gap-3">
                <DropdownMenu>
                  <DropdownMenuTrigger className="bg-white/90 text-primary px-4 py-2 rounded-lg font-medium border border-muted flex items-center gap-1 shadow-sm hover:bg-white transition-colors duration-200">
                    {chain?.name.split(" ").slice(0, 2).join(" ")} <ChevronDown className="h-4 w-4 ml-1" />
                  </DropdownMenuTrigger>
                  <DropdownMenuContent className="w-full justify-center rounded-md shadow-md border border-muted">
                    {chains.map(
                      (c) =>
                        c.id !== chain?.id && (
                          <DropdownMenuItem
                            key={c.id}
                            onClick={() => switchChain({ chainId: c.id })}
                            className="cursor-pointer w-full flex justify-center font-medium hover:bg-muted"
                          >
                            {c.name}
                          </DropdownMenuItem>
                        )
                    )}
                  </DropdownMenuContent>
                </DropdownMenu>
                
                <DropdownMenu>
                  <DropdownMenuTrigger className="bg-gradient-to-r from-primary to-primary/90 text-white px-4 py-2 rounded-lg font-medium flex items-center gap-1 shadow-sm hover:shadow-md transition-all duration-200 hover:-translate-y-0.5">
                    {formatAddress(address)} <ChevronDown className="h-4 w-4 ml-1" />
                  </DropdownMenuTrigger>
                  <DropdownMenuContent className="w-full flex justify-center rounded-md shadow-md border border-muted">
                    <DropdownMenuItem
                      onClick={() => disconnect()}
                      className="text-destructive cursor-pointer w-full flex justify-center font-medium hover:bg-muted"
                    >
                      切断する
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>
            ) : (
              <button
                onClick={() => connect({ connector })}
                className="inline-flex items-center gap-2 bg-gradient-to-r from-primary to-primary/90 text-white px-6 py-2.5 rounded-lg font-medium shadow-sm hover:shadow-md transition-all duration-200 hover:-translate-y-0.5"
              >
                <Image 
                  src="/metamask-logo.svg"
                  alt="MetaMask"
                  width={20}
                  height={20}
                  className="w-5 h-5"
                />
                ウォレットを接続
              </button>
            )}
          </div>
          
          {/* モバイルメニューボタン */}
          <div className="md:hidden">
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="bg-white p-2 rounded-full shadow-sm text-foreground focus:outline-none"
            >
              {mobileMenuOpen ? (
                <X className="h-6 w-6" />
              ) : (
                <Menu className="h-6 w-6" />
              )}
            </button>
          </div>
        </div>
      </div>
      
      {/* モバイルメニュー */}
      <div className={`md:hidden ${mobileMenuOpen ? 'block' : 'hidden'} bg-white shadow-lg rounded-b-2xl`}>
        <div className="px-4 pt-2 pb-4 space-y-1">
          <Link
            href="/chat"
            className="flex items-center gap-2 p-3 rounded-lg hover:bg-muted transition-colors duration-200"
            onClick={() => setMobileMenuOpen(false)}
          >
            <MessageSquare className="h-5 w-5 text-primary" />
            <span className="font-medium">チャット</span>
          </Link>
          <Link
            href="/history"
            className="flex items-center gap-2 p-3 rounded-lg hover:bg-muted transition-colors duration-200"
            onClick={() => setMobileMenuOpen(false)}
          >
            <History className="h-5 w-5 text-primary" />
            <span className="font-medium">履歴</span>
          </Link>
          
          {isConnected ? (
            <div className="p-3 space-y-3">
              <div className="flex items-center justify-between p-2 bg-muted rounded-lg">
                <span className="text-sm text-muted-foreground">ネットワーク:</span>
                <span className="font-medium">{chain?.name.split(" ").slice(0, 2).join(" ")}</span>
              </div>
              <div className="flex items-center justify-between p-2 bg-muted rounded-lg">
                <span className="text-sm text-muted-foreground">アドレス:</span>
                <span className="font-medium">{formatAddress(address)}</span>
              </div>
              <button
                onClick={() => {
                  disconnect();
                  setMobileMenuOpen(false);
                }}
                className="w-full p-2 text-center bg-white border border-destructive text-destructive rounded-lg font-medium"
              >
                切断する
              </button>
            </div>
          ) : (
            <button
              onClick={() => {
                connect({ connector });
                setMobileMenuOpen(false);
              }}
              className="w-full mt-2 flex items-center justify-center gap-2 bg-gradient-to-r from-primary to-primary/90 text-white p-3 rounded-lg font-medium"
            >
              <Image 
                src="/metamask-logo.svg"
                alt="MetaMask"
                width={20}
                height={20}
              />
              ウォレットを接続
            </button>
          )}
        </div>
      </div>
    </nav>
  );
}
