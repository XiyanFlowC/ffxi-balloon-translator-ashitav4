# Balloon (Ashita v4 Port) (中文机器翻译集成)

此为[Ashita v4](https://github.com/AshitaXI/Ashita-v4beta)的原始[Balloon移植](https://github.com/onimitch/ffxi-balloon-ashitav4/)集成了基于大语言模型（LLM）的机器翻译支持功能的Addon。利用此Addon，可以实时翻译游戏中的对话。虽然有支持预翻译和术语表，但考虑到文本数量，可能存在性能问题，未来的优化正在计划中，可能通过C模块来解决。

原始的Windower Balloon由Hando制作，由Kenshi，Yuki和Ghosty修改，由onimitch移植到Ashita v4。

## 如何启用
在游戏中输入
```
/addon load balloon
```

### 翻译功能
你需要获取LLM的调用API，然后这样录入：
```
/balloon translate add <名字>
/balloon translate use <名字>
/balloon translate set api_key <你获取到的API_KEY>
/balloon translate set base_url <API文档指明的基础路径>
/balloon translate set endpoint <API文档指明的端点>
/balloon translate set req_para <API文档指明的要求的键> <API文档指明的要求的值>
...
```
通常，你需要录入以上信息，以硅基流动的API为例：
```
/balloon translate add siliconflow
/balloon translate use siliconflow
/balloon translate set api_key sk-52f******
/balloon translate set base_url https://api.siliconflow.cn
/balloon translate set endpoint /v1/chat/completions
/balloon translate set req_para model deepseek-ai/DeepSeek-V3
```

然后，使用`/balloon translate`来启用翻译功能。

默认包括一个sakura配置集，可通过`/balloon translate use sakura`使用，使用此配置将调用本地部署的SakuraLLM。

#### 替代配置方案
如果你认为通过游戏文本命令设定配置很麻烦，也可以手动编辑config文件。另外，也可以不使用配置集（`/balloon translate use none`），这种情况下，将使用`Translator.lua`中的config里的参数。你可自行编辑该Lua文件来配置。

## 指令
你可以使用 /balloon 或 /bl 命令来操作对话框设置。

`/balloon 0` - 隐藏对话框，并在游戏日志窗口中显示NPC文本。

`/balloon 1` - 显示对话框，并从游戏日志窗口中隐藏NPC文本。

`/balloon 2` - 显示对话框，并在游戏日志窗口中显示NPC文本。

`/balloon reset` - 将所有设置重置为默认值。

`/balloon reset pos` - 重置对话框的位置。

`/balloon theme <theme>` - 切换主题（有关主题的详细信息请见下文）。

`/balloon scale <scale>` - 按小数比例调整对话框的大小（例如：1.5）。

`/balloon delay <seconds>` - 设置无提示对话框关闭前的延迟时间（以秒为单位）。

`/balloon speed <chars per second>` - 设置文本显示速度（以每秒字符数为单位）。设置为0以禁用。

`/balloon portrait` - 切换角色肖像的显示（如果主题支持）。

`/balloon move_close` - 切换玩家移动时对话框自动关闭的功能。

`/balloon always_on_top` - 切换始终置顶模式（IMGUI模式）。此模式使用IMGUI渲染最终元素，确保对话框始终显示在其他自定义UI的前面。如果此模式出现问题，可以使用此命令禁用它。

`/balloon in_combat` - 切换战斗中是否显示对话框（默认关闭）。

`/balloon system` - 切换是否显示系统消息的对话框，例如传送点（默认开启）。

`/balloon cinematic` - 切换电影模式 - 在过场动画中自动隐藏游戏UI（默认开启）。

`/balloon fps` - 切换过场动画中的FPS控制，以防止某些过场动画中的卡顿（默认开启）。

`/balloon test <name> <lang> <mode>` - 显示一个测试对话框。Lang: "-"（自动）, "en" 或 "ja"。Mode: 1（对话）, 2（系统）。

`/balloon test` - 列出所有可用的测试。

### 为翻译模块添加的指令
`/balloon translate` 或 `/balloon tr` - 启用或禁用翻译功能。

`/balloon translate use <配置名>` - 选择一个配置集来使用。

`/balloon translate use none` - 不要使用配置集。利用Translate内置的设定进行请求。

`/balloon translate use classic` - 使用谷歌翻译。

`/balloon translate list` - 列出所有配置集及其配置。

`/balloon translate add <配置名>` - 添加一个配置集。

`/balloon translate remove <配置名>` - 移除一个配置集。

`/balloon translate set api_key <API密钥>` - 设定当前配置集的API密钥。

`/balloon translate set base_url <基础URL>` - 设定当前配置集使用的基础URL。

`/balloon translate set endpoint <端点>` - 设定当前配置集要调用的API端点。

`/balloon translate set req_para <键> <值>` - 设定当前配置集的请求参数。

-------------------

# Balloon (Ashita v4 Port) (Chinese Machine Translation Integration)

This is an addon for the original Balloon port of Ashita v4 with machine translation support based on Large Language Model (LLM). With this addon, in-game dialogues can be translated in real time. Although there is support for pre-translation and glossary, there may be performance issues given the amount of text, and future optimizations are planned, which may be solved through C modules.

The original Windower Balloon was made by Hando, modified by Kenshi, Yuki and Ghosty, and ported to Ashita v4 by onimitch.

## How to enable
Input in the game
```
/addon load balloon
```

### Translation function
You need to obtain the LLM call API and enter it like this:
```
/balloon translate add <name>
/balloon translate use <name>
/balloon translate set api_key <API_KEY you obtained>
/balloon translate set base_url <Base path specified by the API document>
/balloon translate set endpoint <Endpoint specified by the API document>
/balloon translate set req_para <Key specified by the API document> <Value specified by the API document>
...
```
Usually, you need to enter the above information, taking the silicon flow API as an example:
```
/balloon translate add siliconflow
/balloon translate use siliconflow
/balloon translate set api_key sk-52f******
/balloon translate set base_url https://api.siliconflow.cn
/balloon translate set endpoint /v1/chat/completions
/balloon translate set req_para model deepseek-ai/DeepSeek-V3
```

Then, use `/balloon translate` to enable translation.

A sakura configuration set is included by default, which can be used by `/balloon translate use sakura`, which will call the locally deployed SakuraLLM.

#### Alternative configuration schemes
If you think it is troublesome to set the configuration through the game text commands, you can also edit the config file manually. Alternatively, you can not use the configuration set (`/balloon translate use none`), in which case the parameters in the config in `Translator.lua` will be used. You can edit the Lua file to configure it yourself.

## Commands
### Commands added for the translation module
`/balloon translate` or `/balloon tr` - Enable or disable translation.

`/balloon translate use <configuration name>` - Select a configuration set to use.

`/balloon translate use none` - Do not use a configuration set. Use Translate's built-in settings for the request.

`/balloon translate use classic` - Use Google Translate.

`/balloon translate list` - List all configuration sets and their configurations.

`/balloon translate add <configuration name>` - Add a configuration set.

`/balloon translate remove <configuration name>` - Remove a configuration set.

`/balloon translate set api_key <API key>` - Set the API key for the current configuration set.

`/balloon translate set base_url <base URL>` - Set the base URL used by the current configuration set.

`/balloon translate set endpoint <endpoint>` - Set the API endpoint to be called by the current configuration set.

`/balloon translate set req_para <key> <value>` - Sets a request key-value pair for the current  configuration set.



原始README：
-------------------

This is an [Ashita v4](https://github.com/AshitaXI/Ashita-v4beta) port of the Balloon addon, forked from [StarlitGhost's version](https://github.com/StarlitGhost/Balloon).

The original Windower Balloon addon was created by Hando and modified by Kenshi, Yuki and Ghosty.

This Ashita v4 port was created by onimitch.

![Example default](https://github.com/onimitch/ffxi-balloon-ashitav4/blob/main/Example-default.png "Example default")

## How to install:
1. Download the latest Release from the [Releases page](https://github.com/onimitch/ffxi-balloon-ashitav4/releases)
2. Extract the **_balloon_** folder to your **_Ashita4/addons_** folder

## How to enable it in-game:
1. Login to your character in FFXI
2. Type `/addon load balloon`

## How to have Ashita load it automatically:
1. Go to your Ashita v4 folder
2. Open the file **_Ashita4/scripts/default.txt_**
3. Add `/addon load balloon` to the list of addons to load under "Load Plugins and Addons"

## Commands

You can use `/balloon` or `/bl`

`/balloon 0` - Hide balloon & display npc text in game log window.

`/balloon 1` - Show balloon & hide npc text from game log window.

`/balloon 2` - Show balloon & display npc text in game log window.

`/balloon reset` - Reset all settings back to default.

`/balloon reset pos` - Reset the balloon position.

`/balloon theme <theme>` - Switch theme (see below for info on Themes).

`/balloon scale <scale>` - Scales the size of the balloon by a decimal (eg: 1.5).

`/balloon delay <seconds>` - Delay before closing promptless balloons.

`/balloon speed <chars per second>` - Speed that text is displayed, in characters per second. Set to 0 to disable.

`/balloon portrait` - Toggle the display of character portraits, if the theme has settings for them.

`/balloon move_close` - Toggle balloon auto-close on player movement.

`/balloon always_on_top` - Toggle always on top (IMGUI mode). This mode renders the final elements using IMGUI to ensure Balloon always appears in front of any other custom UI. If for some reason you have issues with this mode, you can use this command to disable it.

`/balloon in_combat` - Toggle displaying balloon during combat (off by default).

`/balloon system` - Toggle displaying balloon for system messages, e.g Home Points. (on by default).

`/balloon cinematic` - Toggle cinematic mode - auto hide game UI during cutscenes (on by default).

`/balloon fps` - Toggle fps control during cutscenes to prevent lockups in certain cutscenes (on by default).

`/balloon test <name> <lang> <mode>` - Display a test bubble. Lang: "-" (auto), "en" or "ja". Mode: 1 (dialogue), 2 (system).

`/balloon test` - List all available tests.

## Cinematic mode

Balloon will auto hide the game UI during a cutscene and handle key/button presses to continue the dialogue.
If the game presents you with options during a cutscene, Balloon will temporarily re-show the game UI and hide it again once you've made a selection.

Cinematic mode is enabled by default. 
If you want to turn it off, you can toggle the option using `/balloon cinematic`.

## Moving balloon

While the balloon is open you can use the mouse to click and drag it to move it around.

## Themes

There are currently four themes bundled with the addon.

### default

![Example default](https://github.com/onimitch/ffxi-balloon-ashitav4/blob/main/Example-default.png "Example default")

### ffvii-r

Requires "Libre Franklin Medium" or "Libre Franklin Regular" font, which you can get free from [Google Fonts](https://fonts.google.com/specimen/Libre+Franklin). Install the font in Windows.

![Example ffvii-r](https://github.com/onimitch/ffxi-balloon-ashitav4/blob/main/Example-ffvii-r.png "Example ffvii-r")

### ffxi

![Example ffxi](https://github.com/onimitch/ffxi-balloon-ashitav4/blob/main/Example-ffxi.png "Example ffxi")

### snes-ff

Uses "DotGothic16" font, which you can get free from [Google Fonts](https://fonts.google.com/specimen/DotGothic16). Install the font in Windows.

Alternatively it will look for "DePixel" font if "DotGothic16" not installed, which you can get free from [Be Fonts](https://befonts.com/depixel-font-family.html).

![Example snes-ff](https://github.com/onimitch/ffxi-balloon-ashitav4/blob/main/Example-snes-ff.png "Example snes-ff")

## Theme customisation

If you want to customise a theme, copy one of the existing themes from `addons/balloon/themes` into `config/addons/balloon/themes`.

Example: `config/addons/balloon/themes/my_theme`.

In game switch to your new theme: `/balloon theme my_theme`.

Edit the theme.xml file as you wish, or replace the pngs with alternatives. Sorry there isn't any more help on this for now but hopefully the existing themes are enough to figure out how it works.

Reload the theme by using: `/balloon theme my_theme`.

See your changes immediately by using one of the test prompts:

e.g: `/balloon test bahamut` or `/balloon test colors`.


## Issues/Support

I only have limited time available to offer support, but if you have a problem, have discovered a bug or want to request a feature, please [create an issue on GitHub](https://github.com/onimitch/ffxi-balloon-ashitav4/issues).


## Gdifonts

This addon uses a custom fork of ThornyXI's gdifonts and gdifonttextures, in order to support colored regions and clipping:

https://github.com/onimitch/gdifonts/tree/regions

https://github.com/onimitch/gdifonttexture/tree/regions
