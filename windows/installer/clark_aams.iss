; 珂拉课程表 Windows 安装包脚本。
;
; 用法（在仓库根目录执行）：
;   ISCC.exe windows/installer/clark_aams.iss /DAppVersion=1.9.0 /DAppBuild=25
;
; 打包前请先执行 flutter build windows --release，
; 安装包会把 build/windows/x64/runner/Release 整个目录收进去。

#ifndef AppVersion
  #define AppVersion "1.9.0"
#endif
#ifndef AppBuild
  #define AppBuild "25"
#endif

#define AppName "珂拉课程表"
#define AppPublisher "Provias"
#define AppUrl "https://github.com/TissyBoxC/Clark_AAMS"
#define AppExeName "clark_aams.exe"

[Setup]
AppId={{8E4C1F6A-3B2D-4A57-9C11-6D2E5F7A4B83}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppUrl}
AppSupportURL={#AppUrl}
AppUpdatesURL={#AppUrl}
DefaultDirName={autopf}\ClarkAAMS
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
; 应用本身是 64 位，装到 64 位程序目录。
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; 未签名安装包，关闭"文件属性里没有版本信息"这类无害告警。
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
OutputDir=..\..\out
OutputBaseFilename=Clark_AAMS_{#AppVersion}_windows_x64

[Languages]
; 中文语言文件随仓库提供：Inno Setup 6 本身不带简体中文，
; 从官网单独取一份放在 installer/languages 下，本机与 CI 用的是同一份。
Name: "chinesesimplified"; MessagesFile: "languages\ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务："

[Files]
; 整个 Release 目录一起收：可执行文件、Dart 数据、插件 DLL、WebView2 加载器。
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; \
  Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\卸载 {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "立即打开 {#AppName}"; \
  Flags: nowait postinstall skipifsilent

[UninstallDelete]
; 卸载时清掉运行中生成的缓存目录。
Type: filesandordirs; Name: "{app}\data"
