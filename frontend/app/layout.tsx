import type { Metadata } from "next";
import { Poppins } from "next/font/google";
import { headers } from "next/headers";
import { cookieToInitialState } from "wagmi";
import "./globals.css";
import { getConfig } from "@/wagmi.config";
import { Providers } from "./providers";
import { Navbar } from "@/components/navbar";

const poppins = Poppins({
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700"],
  variable: "--font-poppins",
});

export const metadata: Metadata = {
  title: "Myrdal | オンチェーンAIエージェント",
  description: "オンチェーン上で自律的に動作する汎用AIエージェント、Myrdalのウェブアプリケーション",
};

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const initialState = cookieToInitialState(
    getConfig(),
    (await headers()).get("cookie") ?? ""
  );
  
  return (
    <html lang="ja">
      <body className={`${poppins.variable} text-foreground antialiased`}>
        {/* ノルディックスタイルの背景要素 */}
        <div className="fixed inset-0 w-full h-full z-[-20]"></div>
        
        {/* デコレーティブな背景要素 */}
        <div className="fixed top-0 right-0 w-1/3 h-1/3 opacity-5 z-[-15]">
          <svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
            <path fill="currentColor" d="M39.9,-68.5C52.8,-62.3,65.2,-53.3,73.1,-40.9C81,-28.6,84.3,-14.3,84.3,-0.1C84.3,14.2,80.8,28.4,73.5,40.6C66.2,52.8,55,63,42,70.2C29,77.4,14.5,81.7,0,81.6C-14.5,81.6,-29,77.4,-42,70.1C-55,62.8,-66.5,52.4,-73.7,39.6C-80.9,26.7,-83.7,13.4,-83.7,0C-83.6,-13.4,-80.7,-26.7,-73.6,-38.4C-66.5,-50.1,-55.2,-60.1,-42.3,-66.2C-29.4,-72.3,-14.7,-74.6,-0.2,-74.2C14.2,-73.9,28.4,-71,39.9,-68.5Z" transform="translate(100 100)" />
          </svg>
        </div>
        
        <div className="fixed bottom-0 left-0 w-1/3 h-1/3 opacity-5 z-[-15]">
          <svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
            <path fill="currentColor" d="M39.2,-65.9C47.7,-60.5,49.6,-43.5,53.3,-30C57,-16.4,62.3,-6.3,66.3,6.6C70.3,19.5,73,36,67.3,48.5C61.6,61,47.5,69.4,33.4,70.8C19.3,72.2,5.3,66.5,-7.8,62.3C-20.8,58.1,-32.8,55.3,-44.2,49C-55.7,42.7,-66.6,32.9,-67.3,21.6C-68,10.3,-58.4,-2.4,-51.8,-14.3C-45.2,-26.1,-41.6,-37.1,-33.8,-42.8C-26,-48.5,-14,-49,-0.6,-48.1C12.8,-47.2,30.7,-71.4,39.2,-65.9Z" transform="translate(100 100)" />
          </svg>
        </div>
        
        <main className="flex flex-col mx-auto">
          <Providers initialState={initialState}>
            <Navbar />
            {children}
          </Providers>
        </main>
      </body>
    </html>
  );
}
