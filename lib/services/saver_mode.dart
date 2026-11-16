import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 省流模式：一道压过会话记忆的硬闸。
///
/// 开着时，所有短剧播放（全页播放器 + feed 内联）起播一律落在 360P，手点
/// 更高档位也不生效；关掉即回到「记忆档 → 默认 360P」的原逻辑。
///
/// 与 [QualityMemory] 的分工：那是「这次手点过哪档」的会话记忆（不落盘、
/// 进程死即忘），这是「不许走高码率」的开关，所以要落盘、要跨启动。
/// 播放器更多面板上的开关行读写它。
class SaverMode {
  const SaverMode._();

  /// 落盘键（本项目自加项，官方客户端无此功能）。
  static const storeKey = 'saver_mode_360p';

  /// 省流档名：与官方多档流里的 `360P` 档名一致（没有该档时按原逻辑
  /// 退到最低档，见 `EpisodeSource.withPreferredQuality`）。
  static const forcedName = '360P';

  /// 开关状态。面板开关与起播路径共同读它。
  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  static bool get isOn => enabled.value;

  /// 起播档名：开着给 `360P`，关着给 null（交回记忆档/默认档）。
  static String? get forcedQualityName => enabled.value ? forcedName : null;

  /// 启动装配链里读一次；读盘失败退化为关闭——省流是加分项，不拖播放。
  static Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      enabled.value = preferences.getBool(storeKey) ?? false;
    } catch (_) {
      enabled.value = false;
    }
  }

  /// 面板开关写入口。内存态先翻（面板与起播立刻看到新值），落盘失败只
  /// 影响下次启动的初值，不回滚本次选择。
  static Future<void> setEnabled(bool value) async {
    enabled.value = value;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(storeKey, value);
    } catch (_) {
      // 本次已生效，忽略落盘失败。
    }
  }
}
