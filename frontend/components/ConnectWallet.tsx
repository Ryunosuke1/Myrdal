import { useAccount, useConnect, useDisconnect } from 'wagmi';
import { metaMask } from 'wagmi/connectors';
import Image from 'next/image';

export const ConnectWallet = () => {
  const { address, isConnected } = useAccount();
  const { connect } = useConnect();
  const { disconnect } = useDisconnect();
  
  // アドレスを短縮表示する関数
  const shortenAddress = (addr) => {
    if (!addr) return '';
    return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
  };
  
  if (isConnected) {
    return (
      <div className="flex items-center gap-3">
        <div className="hidden md:flex items-center gap-2 px-3 py-1.5 rounded-full bg-primary/10 text-primary text-sm">
          <div className="w-2 h-2 rounded-full bg-green-500"></div>
          <span>{shortenAddress(address)}</span>
        </div>
        
        <button
          onClick={() => disconnect()}
          className="vy-button-secondary text-sm py-1.5"
        >
          切断
        </button>
      </div>
    );
  }
  
  return (
    <button
      onClick={() => connect({ connector: metaMask() })}
      className="vy-button-primary flex items-center gap-2"
    >
      <Image
        src="/metamask-fox.svg"
        alt="MetaMask"
        width={20}
        height={20}
      />
      <span>ウォレット接続</span>
    </button>
  );
};
