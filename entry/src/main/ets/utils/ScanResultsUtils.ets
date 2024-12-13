import { KvUtil } from "@pura/harmony-utils";
import { ScanResults } from "../model/ScanService";

export class ScanResultsUtils {
  // 保存ScanResults对象的函数（与之前相同，但确保timestamp被保存）
  static async saveScanResults(scanResults: ScanResults): Promise<void> {
    const key = ScanResultsUtils.generateUniqueKey();
    scanResults.timestamp=Date.now()
    const serializedScanResults = JSON.stringify(scanResults);
    await KvUtil.put(key, serializedScanResults);
  }

  // 生成唯一键的函数（使用UUID或其他方法）
  private static generateUniqueKey(): string {
    // 这里使用简单的时间戳加随机数作为示例
    return `scanResult_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  // 检索并展示所有ScanResults对象的函数，根据timestamp排序
  static async retrieveAndSortScanResults(): Promise<ScanResults[]> {
    const entries = await KvUtil.getEntries('scanResult_'); // 检索所有键值对
    const scanResultsList: ScanResults[] = [];

    for (const entry of entries) {
      if (typeof entry.value === 'string') {
        try {
          const scanResults = JSON.parse(entry.value) as ScanResults;
          scanResultsList.push(scanResults);
        } catch (e) {
          console.error('Failed to parse ScanResults:', e);
        }
      } else {
        console.error('Unexpected value type:', typeof entry.value);
      }
    }


    // 根据timestamp属性对ScanResults进行排序
    scanResultsList.sort((a, b) => a.timestamp - b.timestamp);

    return scanResultsList;
  }



}


