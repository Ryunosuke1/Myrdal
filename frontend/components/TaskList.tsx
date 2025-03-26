import { useAccount } from 'wagmi';
import { useMyrdalContract } from '../hooks/useMyrdalContract';
import { useState, useEffect } from 'react';

export const TaskList = () => {
  const { address } = useAccount();
  const { useUserTasks, useTaskInfo } = useMyrdalContract();
  const [selectedTaskId, setSelectedTaskId] = useState(null);
  
  // ユーザーのタスク一覧を取得
  const { data: userTasks, isLoading: isTasksLoading } = useUserTasks(address);
  
  // 選択されたタスクの詳細を取得
  const { data: taskInfo, isLoading: isTaskInfoLoading } = useTaskInfo(selectedTaskId);
  
  // タスクステータスのラベル
  const getStatusLabel = (status) => {
    switch (status) {
      case 0: return { text: '保留中', color: 'bg-amber-100 text-amber-800' };
      case 1: return { text: '処理中', color: 'bg-blue-100 text-blue-800' };
      case 2: return { text: '完了', color: 'bg-green-100 text-green-800' };
      case 3: return { text: '失敗', color: 'bg-red-100 text-red-800' };
      default: return { text: '不明', color: 'bg-gray-100 text-gray-800' };
    }
  };
  
  // 日時のフォーマット
  const formatDate = (timestamp) => {
    if (!timestamp || timestamp === 0) return '未設定';
    return new Date(Number(timestamp) * 1000).toLocaleString('ja-JP');
  };
  
  if (!address) {
    return (
      <div className="vy-card">
        <div className="p-4 text-center">
          <p className="text-gray-500">タスク一覧を表示するにはウォレットを接続してください。</p>
        </div>
      </div>
    );
  }
  
  if (isTasksLoading) {
    return (
      <div className="vy-card">
        <div className="p-4 text-center">
          <p className="text-gray-500">タスク一覧を読み込み中...</p>
        </div>
      </div>
    );
  }
  
  if (!userTasks || userTasks.length === 0) {
    return (
      <div className="vy-card">
        <div className="p-4 text-center">
          <p className="text-gray-500">タスクがありません。新しいタスクを作成してください。</p>
        </div>
      </div>
    );
  }
  
  return (
    <div className="vy-card">
      <h2 className="vy-card-title">あなたのタスク一覧</h2>
      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4">
        {/* タスク一覧 */}
        <div className="md:col-span-1 border-r border-gray-200 pr-4">
          <div className="space-y-2">
            {userTasks.map((taskId) => (
              <div 
                key={taskId} 
                className={`p-3 rounded-md cursor-pointer transition-all ${
                  selectedTaskId === taskId 
                    ? 'bg-primary text-white' 
                    : 'bg-gray-100 hover:bg-gray-200'
                }`}
                onClick={() => setSelectedTaskId(taskId)}
              >
                <div className="font-medium truncate">タスク ID: {taskId.slice(0, 10)}...</div>
              </div>
            ))}
          </div>
        </div>
        
        {/* タスク詳細 */}
        <div className="md:col-span-2">
          {selectedTaskId ? (
            isTaskInfoLoading ? (
              <div className="p-4 text-center">
                <p className="text-gray-500">タスク情報を読み込み中...</p>
              </div>
            ) : taskInfo ? (
              <div className="space-y-4">
                <div>
                  <h3 className="text-lg font-medium">タスク詳細</h3>
                  <div className="mt-2 p-2 bg-gray-50 rounded-md">
                    <p className="text-sm text-gray-500">ID: {taskInfo.id}</p>
                  </div>
                </div>
                
                <div>
                  <h4 className="font-medium">ステータス</h4>
                  <div className={`inline-block px-2 py-1 rounded-full text-sm ${getStatusLabel(taskInfo.status).color}`}>
                    {getStatusLabel(taskInfo.status).text}
                  </div>
                </div>
                
                <div>
                  <h4 className="font-medium">プロンプト</h4>
                  <div className="mt-1 p-3 bg-gray-50 rounded-md">
                    <p>{taskInfo.prompt}</p>
                  </div>
                </div>
                
                {taskInfo.result && (
                  <div>
                    <h4 className="font-medium">結果</h4>
                    <div className="mt-1 p-3 bg-gray-50 rounded-md">
                      <p>{taskInfo.result}</p>
                    </div>
                  </div>
                )}
                
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <h4 className="font-medium text-sm">作成日時</h4>
                    <p className="text-sm">{formatDate(taskInfo.created_at)}</p>
                  </div>
                  <div>
                    <h4 className="font-medium text-sm">完了日時</h4>
                    <p className="text-sm">{formatDate(taskInfo.completed_at)}</p>
                  </div>
                </div>
              </div>
            ) : (
              <div className="p-4 text-center">
                <p className="text-gray-500">タスク情報を取得できませんでした。</p>
              </div>
            )
          ) : (
            <div className="p-4 text-center">
              <p className="text-gray-500">左側のリストからタスクを選択してください。</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
