import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import {
  CosClientError,
  CosError,
  CosErrorCode,
  CosXmlBaseService,
  TransferState,
} from '../../../../../Index';
import { TransferTask } from '../../../../main/ets/transfer/TransferTask';

/**
 * 传输状态机的**纯单元测试**（不依赖网络）。
 *
 * 与 TransferState.test.ets（集成测试，走真实上传/下载）互补：这里直接对
 * TransferTask 内部的 protected 状态机方法做确定性验证，把 1.2.5 随 onState
 * 一起落地的四处修复在本地、离线、可精确断言地固定下来，不受网络快慢/暂停
 * 窗口等环境因素影响：
 *
 *   1. updateState 幂等：状态未变化时不重复回调。
 *   2. markErrorIfActive：Pause/Canceled/Success 不会被覆写为 Error，
 *      只有 Waiting/Processing 等"进行中"状态才会被置为 Error。
 *   3. failed 闩 + resetFailedFlag：一次传输周期内只对外报一次失败；
 *      复位后能再次上报（否则 resume 后再遇失败将永远静默）。
 *   4. 外部 onState 回调抛异常不影响状态机本身。
 */

/**
 * 暴露 TransferTask protected 方法的最小测试子类。
 * 泛型用 object/object，仅用于构造，不触发任何网络行为。
 */
class TestTransferTask extends TransferTask<object, object> {
  constructor(service: CosXmlBaseService) {
    super(service, new Object());
  }

  start(): void {
  }

  pause(): void {
  }

  resume(): void {
  }

  cancel(): void {
  }

  public updateStateForTest(state: TransferState): void {
    this.updateState(state);
  }

  public markErrorIfActiveForTest(): void {
    this.markErrorIfActive();
  }

  public resetFailedFlagForTest(): void {
    this.resetFailedFlag();
  }

  public onFailForTest(err: CosError): void {
    this.onFail(this.objectRequest, err);
  }

  public getStateForTest(): TransferState {
    return this.getState();
  }
}

export default function transferStateMachineTest(cosXmlBaseService: CosXmlBaseService) {
  describe('transferStateMachineTest', () => {
    beforeAll(() => {
    })
    beforeEach(() => {
    })
    afterEach(() => {
    })
    afterAll(() => {
    })

    it('initialStateIsWaiting', 0, (done: Function) => {
      const task = new TestTransferTask(cosXmlBaseService);
      expect(task.getStateForTest()).assertEqual(TransferState.Waiting);
      done();
    })

    it('updateStateIsIdempotent', 0, (done: Function) => {
      // 状态未变化时不重复回调 —— 分块上传中每个分块完成都会走 Processing 分支，
      // 若无幂等保护，Processing 会被回调很多次。
      const task = new TestTransferTask(cosXmlBaseService);
      const states: TransferState[] = [];
      task.onState = (state: TransferState) => {
        states.push(state);
      };

      task.updateStateForTest(TransferState.Processing);
      task.updateStateForTest(TransferState.Processing); // 幂等，不应重复回调
      expect(states.length).assertEqual(1);
      expect(states[0]).assertEqual(TransferState.Processing);
      expect(task.getStateForTest()).assertEqual(TransferState.Processing);

      task.updateStateForTest(TransferState.Success);
      expect(states.length).assertEqual(2);
      expect(states[1]).assertEqual(TransferState.Success);
      done();
    })

    it('markErrorIfActiveDoesNotOverwriteTerminalStates', 0, (done: Function) => {
      // Pause：pause() 取消在途请求，其失败回调不得把 Pause 覆写为 Error
      const paused = new TestTransferTask(cosXmlBaseService);
      paused.updateStateForTest(TransferState.Pause);
      paused.markErrorIfActiveForTest();
      expect(paused.getStateForTest()).assertEqual(TransferState.Pause);

      // Canceled：取消后的失败回调不得覆写
      const canceled = new TestTransferTask(cosXmlBaseService);
      canceled.updateStateForTest(TransferState.Canceled);
      canceled.markErrorIfActiveForTest();
      expect(canceled.getStateForTest()).assertEqual(TransferState.Canceled);

      // Success：已完成的任务不再变更
      const success = new TestTransferTask(cosXmlBaseService);
      success.updateStateForTest(TransferState.Success);
      success.markErrorIfActiveForTest();
      expect(success.getStateForTest()).assertEqual(TransferState.Success);
      done();
    })

    it('markErrorIfActiveOverwritesActiveStates', 0, (done: Function) => {
      // 这是 markErrorIfActive 的反面：真实失败必须落到 Error，不能被"保护"掉。

      // Processing（进行中）→ Error
      const processing = new TestTransferTask(cosXmlBaseService);
      processing.updateStateForTest(TransferState.Processing);
      processing.markErrorIfActiveForTest();
      expect(processing.getStateForTest()).assertEqual(TransferState.Error);

      // Waiting（初始）→ Error
      const waiting = new TestTransferTask(cosXmlBaseService);
      waiting.markErrorIfActiveForTest();
      expect(waiting.getStateForTest()).assertEqual(TransferState.Error);
      done();
    })

    it('failedFlagLatchThenReset', 0, (done: Function) => {
      // failed 闩：一次传输周期内只对外报一次失败。
      // 否则 pause() 置位后，resume() 再遇真实失败时 onResult.onFail 静默不触发。
      const task = new TestTransferTask(cosXmlBaseService);
      let failCount = 0;
      task.onResult = {
        onSuccess: (request, result) => {
        },
        onFail: (request, error) => {
          failCount++;
        }
      };

      const err = new CosClientError(CosErrorCode.UNKNOWN);
      task.onFailForTest(err);
      task.onFailForTest(err); // failed 已置位，不应再报
      expect(failCount).assertEqual(1);

      task.resetFailedFlagForTest();
      task.onFailForTest(err); // 复位后可以再次上报
      expect(failCount).assertEqual(2);
      done();
    })

    it('onStateExceptionDoesNotBreakStateMachine', 0, (done: Function) => {
      // 外部 onState 回调抛异常时，状态机仍应正常推进，不向上抛出。
      const task = new TestTransferTask(cosXmlBaseService);
      task.onState = (state: TransferState) => {
        throw new Error('external callback boom');
      };
      task.updateStateForTest(TransferState.Processing); // 不应抛出
      expect(task.getStateForTest()).assertEqual(TransferState.Processing);

      task.updateStateForTest(TransferState.Success);
      expect(task.getStateForTest()).assertEqual(TransferState.Success);
      done();
    })
  })
}
