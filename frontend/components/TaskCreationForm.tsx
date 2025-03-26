import { useAccount } from 'wagmi';
import { useMyrdalContract } from '../hooks/useMyrdalContract';
import { useState } from 'react';

export const TaskCreationForm = () => {
  const { address } = useAccount();
  const { createTask, isCreateTaskLoading, isCreateTaskTxLoading, isCreateTaskTxSuccess } = useMyrdalContract();
  const [prompt, setPrompt] = useState('');
  
  const handleSubmit = (e) => {
    e.preventDefault();
    if (!prompt.trim()) return;
    
    createTask({
      args: [prompt],
    });
  };
  
  const isLoading = isCreateTaskLoading || isCreateTaskTxLoading;
  
  return (
    <div className="vy-card">
      <h2 className="vy-card-title">新しいタスクを作成</h2>
      
      <form onSubmit={handleSubmit} className="mt-4">
        <div className="mb-4">
          <label htmlFor="prompt" className="vy-label">
            タスクの内容
          </label>
          <textarea
            id="prompt"
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            placeholder="AIエージェントに依頼したいタスクを入力してください..."
            className="vy-textarea"
            rows={4}
            disabled={isLoading}
          />
        </div>
        
        <button
          type="submit"
          className="vy-button-primary w-full"
          disabled={isLoading || !address}
        >
          {isLoading ? (
            <span className="flex items-center justify-center">
              <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              処理中...
            </span>
          ) : (
            'タスクを作成'
          )}
        </button>
        
        {isCreateTaskTxSuccess && (
          <div className="mt-4 p-3 bg-green-50 text-green-700 rounded-md">
            タスクが正常に作成されました！
          </div>
        )}
        
        {!address && (
          <div className="mt-4 p-3 bg-amber-50 text-amber-700 rounded-md">
            タスクを作成するにはウォレットを接続してください。
          </div>
        )}
      </form>
    </div>
  );
};
