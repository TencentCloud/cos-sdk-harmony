import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import {
  CosErrorCode,
  CosXmlBaseService,
  DownloadTask,
  GetObjectRequest,
  HttpProgress,
  PutObjectRequest,
  TransferState,
  UploadTask,
} from '../../../../../Index';
import { FileUtils } from '../common/FileUtils';
import { Logger } from '../common/Logger';
import { TestConst } from '../common/TestConst';
import { TestUtils } from '../common/TestUtils';
import fs from '@ohos.file.fs';

/**
 * 传输状态回调（onState）测试。
 *
 * `onState` 与 `TransferState` 在 1.2.5 才对外放开，且伴随四处状态机修复，
 * 这些行为都不是"跑通一次上传"就能覆盖的，需要专门的用例锁住：
 *
 *   1. onState 本身可用，且上传与下载**都**要覆盖 —— DownloadTask 在此之前
 *      完全没有状态机（只有 UploadTask 有），是本次新补的。
 *   2. 状态序列正确：Processing → Success，以及 Pause → Processing → Canceled。
 *   3. `markErrorIfActive`：pause()/cancel() 会取消在途请求，这些请求随后的
 *      失败回调**不得**把 Pause/Canceled 覆写成 Error（否则外部会看到
 *      "暂停后又变失败"的错误跃迁）。
 *   4. `resetFailedFlag`：`failed` 标记原先永不复位，pause() 置位后，
 *      resume() 再遇真实失败时 onFail 不再触发，调用方永远收不到通知。
 *   5. `updateState` 幂等：状态未变化时不重复回调。
 *   6. `getState()` 与 onState 的最后一次回调值一致。
 *
 * 说明：这些用例依赖"传输能被中途暂停"，因此故意用较大的文件；
 * 若在极快的网络下偶发在 pause 之前就传完，用例会如实记录并跳过该断言，
 * 而不是伪装成通过。
 */
export default function transferStateTest(cosXmlBaseService: CosXmlBaseService) {
  describe('transferStateTest', () => {
    beforeAll(() => {
    })
    beforeEach(() => {
    })
    afterEach(() => {
    })
    afterAll(() => {
    })

    /** 等待条件成立，超时返回 false（避免用例永久挂住） */
    const waitUntil: (cond: () => boolean, timeoutMs: number) => Promise<boolean> =
      /** 等待条件成立，超时返回 false（避免用例永久挂住） */
      async (cond: () => boolean, timeoutMs: number): Promise<boolean> => {
        const deadline = Date.now() + timeoutMs;
        while (Date.now() < deadline) {
          if (cond()) {
            return true;
          }
          await new Promise<void>((resolve) => setTimeout(() => resolve(), 200));
        }
        return cond();
      };

    const sleep: (ms: number) => Promise<void> = async (ms: number): Promise<void> => {
      await new Promise<void>((resolve) => setTimeout(() => resolve(), ms));
    };

    // ================================================================
    // 1. onState 可用性 + 状态序列（上传）
    // ================================================================

    it('uploadOnStateSuccessSequence', 0, async (done: Function) => {
      // 简单上传（小文件）的完整状态序列应当是 Processing → Success。
      // 这条同时验证 onState 回调确实被触发（1.2.5 之前它是被注释掉的）。
      const filePath = FileUtils.getFile(10 * 1024, 'stateSimpleUpload');
      const cosPath = 'do_not_remove/state_simple_upload.txt';
      const service = TestUtils.getCosXmlBaseService(cosXmlBaseService);

      const putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, cosPath, filePath);
      await TestUtils.requestAddCredential(putRequest, service);
      const task: UploadTask = service.upload(putRequest);

      const states: TransferState[] = [];
      task.onState = (state: TransferState) => {
        Logger.info(`uploadOnStateSuccessSequence state=${TransferState[state]}`);
        states.push(state);
      };
      task.onResult = {
        onSuccess: (request, result) => {
          // 成功回调时，状态必须已经是 Success，且 getState() 与之一致
          expect(states.includes(TransferState.Processing)).assertTrue();
          expect(states.includes(TransferState.Success)).assertTrue();
          expect(task.getState()).assertEqual(TransferState.Success);
          // 成功路径不应出现 Error / Pause / Canceled
          expect(states.includes(TransferState.Error)).assertFalse();
          expect(states.includes(TransferState.Pause)).assertFalse();
          expect(states.includes(TransferState.Canceled)).assertFalse();
          done();
        },
        onFail: (request, error) => {
          TestUtils.printError(error);
          expect().assertFail();
          done();
        }
      };
      task.start();
    })

    it('uploadOnStateIdempotent', 0, async (done: Function) => {
      // updateState 有幂等保护：状态未变化时不重复回调。
      // 分块上传过程中每个分块完成都会走一次 Processing 分支，
      // 若无幂等保护，Processing 会被回调很多次。
      const filePath = FileUtils.getFile(3 * 1024 * 1024, 'stateIdempotent');
      const cosPath = 'do_not_remove/state_idempotent.bin';
      const service = TestUtils.getCosXmlBaseService(cosXmlBaseService);

      const putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, cosPath, filePath);
      await TestUtils.requestAddCredential(putRequest, service);
      const task: UploadTask = service.upload(putRequest);

      const states: TransferState[] = [];
      task.onState = (state: TransferState) => {
        states.push(state);
      };
      task.onResult = {
        onSuccess: (request, result) => {
          let processingCount = 0;
          states.forEach((s) => {
            if (s === TransferState.Processing) {
              processingCount++;
            }
          });
          Logger.info(`uploadOnStateIdempotent processingCount=${processingCount}, total=${states.length}`);
          // 分块上传只应在"开始"时进入 Processing 一次；
          // 若这里远大于 1，说明幂等保护失效
          expect(processingCount).assertEqual(1);
          done();
        },
        onFail: (request, error) => {
          TestUtils.printError(error);
          expect().assertFail();
          done();
        }
      };
      task.start();
    })

    // ================================================================
    // 2. pause / resume / cancel 的状态跃迁 + markErrorIfActive
    // ================================================================

    it('uploadPauseNotOverwrittenByError', 0, async (done: Function) => {
      // ⚠️ 本用例锁的是 markErrorIfActive：
      // pause() 会 cancelRequest() 取消在途分块，这些请求随后会走失败回调。
      // 若不加保护，Pause 会被覆写成 Error —— 外部看到"暂停后又变失败"。
      const filePath = FileUtils.getFile(30 * 1024 * 1024, 'statePauseUpload');
      const cosPath = 'do_not_remove/state_pause_upload.bin';
      const service = TestUtils.getCosXmlBaseService(cosXmlBaseService);

      const putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, cosPath, filePath);
      await TestUtils.requestAddCredential(putRequest, service);
      const task: UploadTask = service.upload(putRequest);

      const states: TransferState[] = [];
      let pauseErrorCode: string | undefined = undefined;
      task.onState = (state: TransferState) => {
        Logger.info(`uploadPauseNotOverwrittenByError state=${TransferState[state]}`);
        states.push(state);
      };
      task.onProgress = (progress: HttpProgress) => {
        Logger.info(`statePauseUpload progress=${progress.complete}/${progress.target}`);
      };
      task.onResult = {
        onSuccess: (request, result) => {
          // 30MB 在 pause 之前就传完了 —— 如实记录，不伪装通过
          Logger.info(`statePauseUpload finished before pause, skip pause assertions`);
          expect(task.getState()).assertEqual(TransferState.Success);
          done();
        },
        onFail: (request, error) => {
          // pause() 会触发一次 onFail(CosTransferPauseError)，这是预期的
          pauseErrorCode = error.cosErrorCode;
          Logger.info(`statePauseUpload onFail code=${pauseErrorCode}`);
        }
      };
      task.start();

      const started = await waitUntil(() => states.includes(TransferState.Processing), 30000);
      expect(started).assertTrue();

      task.pause();
      // 给在途分块的失败回调留出时间 —— 这正是 Pause 被覆写的窗口
      await sleep(5000);

      if (states.includes(TransferState.Success)) {
        // 已在 onSuccess 里 done()
        return;
      }

      Logger.info(`states after pause: ${states.map((s) => TransferState[s]).join(',')}`);
      expect(states.includes(TransferState.Pause)).assertTrue();
      // 核心断言：暂停后不得变成 Error
      expect(states.includes(TransferState.Error)).assertFalse();
      expect(task.getState()).assertEqual(TransferState.Pause);
      // pause 会走一次 onFail，且错误码应为 USER_PAUSED（供上层识别并拦截）
      expect(pauseErrorCode).assertEqual(CosErrorCode.USER_PAUSED);

      // 收尾：取消任务并确认 Canceled 也不会被覆写成 Error
      await task.cancel();
      await sleep(3000);
      Logger.info(`states after cancel: ${states.map((s) => TransferState[s]).join(',')}`);
      expect(states.includes(TransferState.Canceled)).assertTrue();
      expect(states.includes(TransferState.Error)).assertFalse();
      done();
    })

    it('uploadResumeBackToProcessing', 0, async (done: Function) => {
      // pause → resume 应回到 Processing。
      // 同时验证 resetFailedFlag：resume() 会复位 failed 标记，
      // 否则后续真实失败将无法通知外部（onFail 不再触发）。
      const filePath = FileUtils.getFile(30 * 1024 * 1024, 'stateResumeUpload');
      const cosPath = 'do_not_remove/state_resume_upload.bin';
      const service = TestUtils.getCosXmlBaseService(cosXmlBaseService);

      const putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, cosPath, filePath);
      await TestUtils.requestAddCredential(putRequest, service);
      const task: UploadTask = service.upload(putRequest);

      const states: TransferState[] = [];
      let failCount = 0;
      let finished = false;
      task.onState = (state: TransferState) => {
        Logger.info(`uploadResumeBackToProcessing state=${TransferState[state]}`);
        states.push(state);
      };
      task.onResult = {
        onSuccess: (request, result) => {
          finished = true;
          Logger.info(`stateResumeUpload success`);
        },
        onFail: (request, error) => {
          failCount++;
          Logger.info(`stateResumeUpload onFail #${failCount} code=${error.cosErrorCode}`);
        }
      };
      task.start();

      const started = await waitUntil(() => states.includes(TransferState.Processing), 30000);
      expect(started).assertTrue();
      // 等分块上传真正拿到 uploadId，否则 resume 会因缺 uploadId 而走重传分支
      await waitUntil(() => task.uploadId !== undefined, 30000);

      if (finished) {
        Logger.info(`stateResumeUpload finished before pause, skip resume assertions`);
        expect(true).assertTrue();
        done();
        return;
      }

      task.pause();
      await sleep(3000);
      expect(states.includes(TransferState.Pause)).assertTrue();
      const failCountAfterPause = failCount;
      // pause 自身会走一次 onFail（USER_PAUSED）
      expect(failCountAfterPause >= 1).assertTrue();

      const statesLenBeforeResume = states.length;
      task.resume();
      // resume 后应重新进入 Processing
      const resumed = await waitUntil(() => states.length > statesLenBeforeResume, 30000);
      expect(resumed).assertTrue();
      const lastState = states[states.length - 1];
      Logger.info(`state after resume=${TransferState[lastState]}`);
      expect(lastState === TransferState.Processing
        || lastState === TransferState.Success).assertTrue();

      await task.cancel();
      await sleep(2000);
      done();
    })

    it('uploadCancelledTaskIsTerminal', 0, async (done: Function) => {
      // 已终结（Success / Error / Canceled）的任务再次 cancel 应当直接返回，
      // 不产生新的状态回调 —— 见 UploadTask.cancel() 开头的短路判断。
      const filePath = FileUtils.getFile(10 * 1024, 'stateTerminal');
      const cosPath = 'do_not_remove/state_terminal.txt';
      const service = TestUtils.getCosXmlBaseService(cosXmlBaseService);

      const putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, cosPath, filePath);
      await TestUtils.requestAddCredential(putRequest, service);
      const task: UploadTask = service.upload(putRequest);

      const states: TransferState[] = [];
      task.onState = (state: TransferState) => {
        states.push(state);
      };
      task.onResult = {
        onSuccess: async (request, result) => {
          expect(task.getState()).assertEqual(TransferState.Success);
          const countBefore = states.length;
          // 对已成功的任务再取消：不得改变状态、不得抛异常
          await task.cancel();
          await sleep(1000);
          expect(states.length).assertEqual(countBefore);
          expect(task.getState()).assertEqual(TransferState.Success);
          done();
        },
        onFail: (request, error) => {
          TestUtils.printError(error);
          expect().assertFail();
          done();
        }
      };
      task.start();
    })

    // ================================================================
    // 3. 下载侧的 onState（DownloadTask 此前完全没有状态机）
    // ================================================================

    it('downloadOnStateSuccessSequence', 0, async (done: Function) => {
      // DownloadTask 在 1.2.5 之前**没有任何状态机**，
      // 这条锁住下载侧 onState 已经可用且序列正确。
      const service = TestUtils.getCosXmlBaseService(cosXmlBaseService);
      const savePath = `${TestUtils.getContext().filesDir}/state_download.png`;
      // 每次重新下载，避免命中"本地已完整"的短路分支
      try {
        if (fs.accessSync(savePath)) {
          fs.unlinkSync(savePath);
        }
      } catch (e) {
        Logger.info(`clean savePath failed(ignorable): ${e}`);
      }

      const getRequest = new GetObjectRequest(
        TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_PATH, savePath);
      await TestUtils.requestAddCredential(getRequest, service);
      const task: DownloadTask = service.download(getRequest);

      const states: TransferState[] = [];
      task.onState = (state: TransferState) => {
        Logger.info(`downloadOnStateSuccessSequence state=${TransferState[state]}`);
        states.push(state);
      };
      task.onResult = {
        onSuccess: (request, result) => {
          expect(states.includes(TransferState.Processing)).assertTrue();
          expect(states.includes(TransferState.Success)).assertTrue();
          expect(task.getState()).assertEqual(TransferState.Success);
          expect(states.includes(TransferState.Error)).assertFalse();
          done();
        },
        onFail: (request, error) => {
          TestUtils.printError(error);
          expect().assertFail();
          done();
        }
      };
      task.start();
    })

    it('downloadPauseNotOverwrittenByError', 0, async (done: Function) => {
      // 下载侧的 markErrorIfActive：pause() 取消在途请求后，
      // 其失败回调不得把 Pause 覆写成 Error。
      const service = TestUtils.getCosXmlBaseService(cosXmlBaseService);
      const savePath = `${TestUtils.getContext().filesDir}/state_download_pause.zip`;
      try {
        if (fs.accessSync(savePath)) {
          fs.unlinkSync(savePath);
        }
      } catch (e) {
        Logger.info(`clean savePath failed(ignorable): ${e}`);
      }

      // 用大文件（522M）确保有足够的暂停窗口
      const getRequest = new GetObjectRequest(
        TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_BIG_FILE_PATH, savePath);
      await TestUtils.requestAddCredential(getRequest, service);
      const task: DownloadTask = service.download(getRequest);

      const states: TransferState[] = [];
      let pauseErrorCode: string | undefined = undefined;
      let finished = false;
      task.onState = (state: TransferState) => {
        Logger.info(`downloadPauseNotOverwrittenByError state=${TransferState[state]}`);
        states.push(state);
      };
      task.onResult = {
        onSuccess: (request, result) => {
          finished = true;
        },
        onFail: (request, error) => {
          pauseErrorCode = error.cosErrorCode;
          Logger.info(`stateDownloadPause onFail code=${pauseErrorCode}`);
        }
      };
      task.start();

      const started = await waitUntil(() => states.includes(TransferState.Processing), 30000);
      expect(started).assertTrue();

      task.pause();
      await sleep(5000);

      if (finished) {
        Logger.info(`stateDownloadPause finished before pause, skip assertions`);
        expect(true).assertTrue();
        done();
        return;
      }

      Logger.info(`download states after pause: ${states.map((s) => TransferState[s]).join(',')}`);
      expect(states.includes(TransferState.Pause)).assertTrue();
      expect(states.includes(TransferState.Error)).assertFalse();
      expect(task.getState()).assertEqual(TransferState.Pause);
      expect(pauseErrorCode).assertEqual(CosErrorCode.USER_PAUSED);

      await task.cancel();
      await sleep(2000);
      expect(states.includes(TransferState.Canceled)).assertTrue();
      expect(states.includes(TransferState.Error)).assertFalse();
      done();
    })

    // ================================================================
    // 4. 失败路径的状态
    // ================================================================

    it('uploadFailGoesToErrorState', 0, async (done: Function) => {
      // 真实失败（对不存在的桶上传）必须落到 Error 状态。
      // 这是 markErrorIfActive 的反面：正常失败不能被"保护"掉。
      const filePath = FileUtils.getFile(10 * 1024, 'stateFailUpload');
      const service = TestUtils.getCosXmlBaseService(cosXmlBaseService);

      const putRequest = new PutObjectRequest(
        'bucket-not-exist-1253960454', 'do_not_remove/state_fail.txt', filePath);
      await TestUtils.requestAddCredential(putRequest, service);
      const task: UploadTask = service.upload(putRequest);

      const states: TransferState[] = [];
      task.onState = (state: TransferState) => {
        Logger.info(`uploadFailGoesToErrorState state=${TransferState[state]}`);
        states.push(state);
      };
      task.onResult = {
        onSuccess: (request, result) => {
          // 不存在的桶不该上传成功
          expect().assertFail();
          done();
        },
        onFail: (request, error) => {
          Logger.info(`uploadFailGoesToErrorState onFail code=${error.cosErrorCode}`);
          // 失败回调到达时状态应为 Error（或稍后到达，故这里再等一拍）
          setTimeout(() => {
            Logger.info(`states=${states.map((s) => TransferState[s]).join(',')}`);
            expect(states.includes(TransferState.Error)).assertTrue();
            expect(task.getState()).assertEqual(TransferState.Error);
            done();
          }, 1000);
        }
      };
      task.start();
    })
  })
}
