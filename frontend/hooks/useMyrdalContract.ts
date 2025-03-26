import { useContractRead, useContractWrite, useWaitForTransaction } from 'wagmi';
import MyrdalCoreABI from '../lib/contracts/MyrdalCore.abi.json';

// コントラクトアドレスは実際のデプロイ後に更新する必要があります
const CONTRACT_ADDRESS = '0x0000000000000000000000000000000000000000';

export function useMyrdalContract() {
  // タスク作成関数
  const { 
    data: createTaskData, 
    isLoading: isCreateTaskLoading, 
    isSuccess: isCreateTaskSuccess, 
    write: createTask 
  } = useContractWrite({
    address: CONTRACT_ADDRESS,
    abi: MyrdalCoreABI,
    functionName: 'create_task',
  });

  // タスク作成トランザクション待機
  const { 
    isLoading: isCreateTaskTxLoading, 
    isSuccess: isCreateTaskTxSuccess 
  } = useWaitForTransaction({
    hash: createTaskData?.hash,
  });

  // ユーザーのタスク一覧取得
  const useUserTasks = (userAddress) => {
    return useContractRead({
      address: CONTRACT_ADDRESS,
      abi: MyrdalCoreABI,
      functionName: 'get_user_tasks',
      args: [userAddress],
      watch: true,
    });
  };

  // タスク情報取得
  const useTaskInfo = (taskId) => {
    return useContractRead({
      address: CONTRACT_ADDRESS,
      abi: MyrdalCoreABI,
      functionName: 'get_task',
      args: [taskId],
      watch: true,
    });
  };

  // タスク完了関数（オーナーのみ）
  const { 
    data: completeTaskData, 
    isLoading: isCompleteTaskLoading, 
    isSuccess: isCompleteTaskSuccess, 
    write: completeTask 
  } = useContractWrite({
    address: CONTRACT_ADDRESS,
    abi: MyrdalCoreABI,
    functionName: 'complete_task',
  });

  // タスク完了トランザクション待機
  const { 
    isLoading: isCompleteTaskTxLoading, 
    isSuccess: isCompleteTaskTxSuccess 
  } = useWaitForTransaction({
    hash: completeTaskData?.hash,
  });

  // タスク総数取得
  const useTaskCount = () => {
    return useContractRead({
      address: CONTRACT_ADDRESS,
      abi: MyrdalCoreABI,
      functionName: 'task_count',
      watch: true,
    });
  };

  // コントラクトオーナー取得
  const useContractOwner = () => {
    return useContractRead({
      address: CONTRACT_ADDRESS,
      abi: MyrdalCoreABI,
      functionName: 'owner',
      watch: true,
    });
  };

  // 一時停止状態取得
  const useContractPaused = () => {
    return useContractRead({
      address: CONTRACT_ADDRESS,
      abi: MyrdalCoreABI,
      functionName: 'paused',
      watch: true,
    });
  };

  return {
    // タスク作成
    createTask,
    isCreateTaskLoading,
    isCreateTaskSuccess,
    isCreateTaskTxLoading,
    isCreateTaskTxSuccess,
    
    // タスク完了
    completeTask,
    isCompleteTaskLoading,
    isCompleteTaskSuccess,
    isCompleteTaskTxLoading,
    isCompleteTaskTxSuccess,
    
    // 読み取り関数
    useUserTasks,
    useTaskInfo,
    useTaskCount,
    useContractOwner,
    useContractPaused,
    
    // コントラクト情報
    contractAddress: CONTRACT_ADDRESS,
    contractABI: MyrdalCoreABI,
  };
}
