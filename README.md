# mod_hw_for_ios

## 简介 | Overview
### English
`mod_hw_for_ios` is a jailbreak-oriented dynamic library that hooks into `MobileGestalt`, `IOKit`, `sysctl`, and selected CoreTelephony entry points in order to rewrite hardware identifiers (serial number, IMEI/MEID, MAC addresses, IDFA/IDFV, and more) at runtime. It is primarily intended for research and debugging around device fingerprint synchronization, and ships with auxiliary Frida scripts plus response filters that expose the data exchanged with iCloud/Apple services.
### 中文
`mod_hw_for_ios` 是一个面向越狱 iOS 设备的动态库项目，通过 hook `MobileGestalt`、`IOKit`、`sysctl` 以及 CoreTelephony 的关键接口，动态改写系统对硬件标识（序列号、IMEI/MEID、MAC、IDFA/IDFV 等）的读取结果。项目主要用于研究/调试设备指纹同步流程，同时附带了一组 Frida 脚本和网络响应过滤逻辑，方便在 iCloud/Apple 服务链路中观察数据。

## 功能亮点 | Feature Highlights
### English
- `src/mobile_gestalt/mobile_gestalt.m` centralizes hooks for `MGCopyAnswer`/`MGCopyMultipleAnswers`, `IORegistryEntry*`, `sysctl`, and identifier APIs such as `ASIdentifierManager` and `UIDevice`, injecting values sourced from `/tmp/devices.plist`.
- CoreTelephony `CTMobileEquipmentInfo` setters are overridden to cache and return deterministic IMEI/MEID data, keeping radio stack and UI in sync.
- `src/captain_hook/hook.mm` leverages CaptainHook to sanitize `LakituResponse` and `EscrowGenericResponse`, which simplifies inspecting or mutating cloud backup metadata.
- Scripts such as `frida/cloudd.js` attach to `akd`, `cloudd`, and other daemons to log selector invocations with stack traces.
- The `txt` folder hosts MobileSubstrate `plist` templates, restart scripts, and sample device profiles, while the `Makefile` automates build, codesign, deployment, and daemon restarts.
### 中文
- 通过 `src/mobile_gestalt/mobile_gestalt.m` 统一拦截 `MGCopyAnswer`/`MGCopyMultipleAnswers`、`IORegistryEntry*`、`sysctl`、`ASIdentifierManager`/`UIDevice` 等 API，将 `/tmp/devices.plist` 中的值注入系统查询结果。
- 针对 CoreTelephony 的 `CTMobileEquipmentInfo`，缓存并改写 `setIMEI` / `setMEID`，确保蜂窝链路与 UI 同步显示一致的标识。
- `src/captain_hook/hook.mm` 使用 CaptainHook 过滤 `LakituResponse`、`EscrowGenericResponse` 的网络返回，便于抓取/修改云端备份元数据。
- `frida/cloudd.js` 等脚本可在需要时附加到 `akd`、`cloudd` 等进程，实时追踪类方法调用和回溯。
- `txt` 目录包含 MobileSubstrate 所需的 `plist`、批量重启脚本和示例设备配置，`Makefile` 则自动完成编译、签名、部署与进程重启。

## 目录结构 | Repository Layout
### English
- `src/mobile_gestalt/`: Core hooks and fingerprint injection logic, plus the `mg_copy_answer_table.h` key mapping.
- `src/cydia_substrate_hook/`: Thin wrappers over Cydia Substrate exposing the `HOOK_FUNCTION/HOOK_MESSAGE` macros.
- `src/captain_hook/`: Network response hooks implemented with CaptainHook.
- `src/code_obfuscator/`: String obfuscation helpers such as the generated `test.auto_gen.h`.
- `src/third_party/`: Bundled dependencies (choose, mongoose, IOKit headers, UIDevice extensions, etc.).
- `frida/`: Debug / instrumentation scripts.
- `bin/` and `adiMachineProvisioning/`: Built dylibs and companion plists for quick deployment.
- `txt/`: Runtime configuration (`devices.plist`, `mod_hw_for_ios.plist`, restart script).
- `ref/`: Reference plists and archives.
### 中文
- `src/mobile_gestalt/`：核心 hook 与设备指纹注入逻辑，含 `mg_copy_answer_table.h` 的字段映射表。
- `src/cydia_substrate_hook/`：对 Cydia Substrate 的轻量封装，提供 `HOOK_FUNCTION/HOOK_MESSAGE` 宏。
- `src/captain_hook/`：网络层 hook、CaptainHook 模板代码。
- `src/code_obfuscator/`：字符串混淆辅助头，生成于 `test.auto_gen.h`。
- `src/third_party/`：包含 choose、mongoose、IOKit headers 以及 UIDevice 扩展等第三方依赖。
- `frida/`：调试脚本。
- `bin/` 与 `adiMachineProvisioning/`：已构建样本（dylib 与 `plist`）。
- `txt/`：部署所需的 `devices.plist`、`mod_hw_for_ios.plist` 与 `killall.sh`。
- `ref/`：对照用的 `plist`/参考资源。

## 构建与部署 | Build & Deployment
### English
**Prerequisites**: macOS with Xcode/iOS SDK (`xcrun`), `ldid2`, `sshpass`, and a jailbroken device reachable over SSH (defaults to `127.0.0.1:2222`, password `alpine`; update the `Makefile` fields to match your setup).

1. Edit `txt/devices.plist` with the spoofed identifiers you want to expose (use `plutil -p txt/devices.plist` to inspect available keys). The `make` target automatically pushes it to `/tmp/devices.plist`.
2. Adjust `txt/mod_hw_for_ios.plist` if you need to customize the MobileSubstrate load configuration.
3. Run `make` (or `make all`). The rule compiles `bin/mod_hw_for_ios.dylib`, signs it via `ldid2`, uploads the dylib/`plist`/`devices.plist`, and runs `txt/killall.sh` plus a `SpringBoard` restart so the hooks take effect.
4. To build locally without touching the device, comment out the `sshpass`/`killall` lines in the `Makefile` or replicate them manually when you're ready to deploy.

> Tip: After deployment, verify `/Library/MobileSubstrate/DynamicLibraries/` and `/tmp/devices.plist` on the device, and tail `log stream --predicate 'process == "SpringBoard"'` for hook output.

### 中文
**依赖**：macOS + Xcode/iOS SDK（用于 `xcrun`）、`ldid2`、`sshpass`、可越狱设备（默认 `127.0.0.1:2222`，密码 `alpine`，可在 `Makefile` 中修改）。

1. 在 `txt/devices.plist` 中填写需要伪装的标识（可使用 `plutil -p txt/devices.plist` 查看字段），并将同名文件 push 至设备 `/tmp/devices.plist`（`make` 目标会自动执行）。
2. 如需调整 Substrate 配置或加载顺序，修改 `txt/mod_hw_for_ios.plist`。
3. 运行 `make`（或 `make all`）。脚本会编译 `bin/mod_hw_for_ios.dylib`，使用 `ldid2` 签名，随后通过 SSH 上传 `dylib`、`plist` 与 `devices.plist`，最后执行 `txt/killall.sh` 和 `SpringBoard` 重启以便生效。
4. 若仅想在本地测试构建，可注释掉 `Makefile` 中的 `sshpass`/`killall` 命令或仿照其逻辑手动部署。

> 提示：部署后可在设备上检查 `/Library/MobileSubstrate/DynamicLibraries/` 与 `/tmp/devices.plist` 是否同步，必要时使用 `log stream --predicate 'process == "SpringBoard"'` 检查 hook 日志。

## 运行机制 | Runtime Behavior
### English
- `initPrefFile()` (inside `src/mobile_gestalt/mobile_gestalt.m`) loads `/tmp/devices.plist` during the constructor phase, converting stringified hex into `CFData` whenever the accompanying `*Data` switch is enabled, so binary answers stay type-safe.
- `HookerForMGCopyAnswer()` and `DeviceDataFilter()` rewrite `MGCopyAnswer` results, mapping obfuscated keys via `mg_copy_answer_table.h`.
- The `HOOK_IOKIT` and `hook_sysctlbyname()` interceptors override queries such as `IOPlatformSerialNumber`, `device-imei`, and `hw.machine`, while `CTMobileEquipmentInfo_setIMEI/MEID()` forces CoreTelephony to expose the spoofed identifiers.
- `HOOK_IDFA()`, `HOOK_IDFV()`, and the `UIDevice identifierForVendor` / `ASIdentifierManager advertisingIdentifier` methods return the configured IDs from `devices.plist`.
- `captain_hook/hook.mm` swaps the init data for `LakituResponse`/`EscrowGenericResponse`, letting `FilterSpecifyFormat()` strip Apple backup records before higher layers consume them.
### 中文
- `initPrefFile()`（`src/mobile_gestalt/mobile_gestalt.m`）会在加载阶段读取 `/tmp/devices.plist`，并根据 `*Data` 标志把字符串转换成 `CFData`，确保二进制字段（如 `WifiAddressData`、`UniqueDeviceIDData`）与原始类型一致。
- `HookerForMGCopyAnswer()` / `DeviceDataFilter()` 对 `MGCopyAnswer` 输出做匹配，将外部配置映射到 MobileGestalt 的 key（包括 `mg_copy_answer_table.h` 中解混淆的条目）。
- `HOOK_IOKIT` 与 `hook_sysctlbyname()` 拦截 `IOPlatformSerialNumber`、`device-imei`、`hw.machine` 等查询，`CTMobileEquipmentInfo_setIMEI/MEID()` 则同步更新蜂窝信息。
- `HOOK_IDFA()`、`HOOK_IDFV()`、`UIDevice identifierForVendor` 以及 `ASIdentifierManager advertisingIdentifier` 会返回 `devices.plist` 中的值。
- `captain_hook/hook.mm` 利用 CaptainHook 动态替换 `LakituResponse`/`EscrowGenericResponse` 的初始化参数，配合 `FilterSpecifyFormat()` 清理 Apple 备份列表中的敏感条目。

## 调试与扩展 | Debugging & Extension
### English
- Attach the Frida helpers (e.g., `frida/cloudd.js`) to iOS daemons from your host Mac to trace `CTMobileEquipmentInfo` or any other Objective-C methods with stack backtraces.
- `txt/killall.sh` restarts a wide range of Apple ID and wireless daemons; trim it down if you only need to relaunch a subset during debugging.
- To add more hooks, extend the mappings inside `src/mobile_gestalt` or rely on the macros defined in `src/cydia_substrate_hook/HookUtil.h` from additional `.m/.mm` files.
### 中文
- 在 macOS 侧可借助 `frida/cloudd.js` 等脚本附加到相关进程，追踪 `CTMobileEquipmentInfo` 的方法调用或栈回溯。
- `txt/killall.sh` 会强制重启大量与 Apple ID/无线服务相关的守护进程，如调试阶段只需重启部分进程，可自行删减脚本中的 `killall` 条目。
- 若需新增 hook，可在 `src/mobile_gestalt` 中扩展 `DeviceDataFilter` 的映射，或使用 `src/cydia_substrate_hook/HookUtil.h` 提供的宏在其他 `.m/.mm` 中定义新函数。

## 致谢与许可 | Credits & License
### English
Third-party code such as choose, mongoose, and the UIDevice extensions remains under their respective licenses (see `src/third_party/choose/LICENSE`, etc.). This project is intended for security research and education only—do not deploy it on devices or in environments where you lack explicit permission.
### 中文
仓库包含了 choose、mongoose、UIDevice 扩展等第三方源文件，请遵循其各自的开源协议（见 `src/third_party/choose/LICENSE` 等）。本项目仅用于安全研究/教学，请勿在未获允许的设备或场景中滥用。
