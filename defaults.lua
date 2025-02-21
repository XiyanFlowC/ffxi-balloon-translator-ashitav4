require('common')

local defaults = T{}

defaults.display_mode = 2
defaults.move_close = true
defaults.no_prompt_close_delay = 10
defaults.text_speed = 100
defaults.theme = 'default'
defaults.scale = 1
defaults.portraits = true
defaults.always_on_top = true
defaults.in_combat = false
defaults.cinematic = true
defaults.system_messages = true
defaults.control_fps = true

defaults.additional_chat_modes = {
    144
}

defaults.trans = {
    config = 'sakura',
    enable = false,
    config_groups = {
        sakura = {
            base_url = 'http://127.0.0.1:8080',
            endpoint = '/v1/chat/completions',
            api_key = '',
            req_para = {
                model = 'SakuraLLM',
                temperature = 0.1,
                top_p = 0.3,
                max_tokens = 512,
                frequency_penalty = 0.1
            }
        },
        deepseek = {
            base_url = 'https://api.deepseek.com',
            endpoint = '/v1/chat/completions',
            api_key = 'YOUR_API_KEY',
            req_para = {
                model = 'deepseek-chat'
            }
        },
        youdao_ = {
            use_special_api = 'youdao_'
        },
        google = {
            use_special_api = 'google'
        }
    }
}

local scaling = require('scaling')
defaults.position = {}
defaults.position.x = scaling.window.w / 2
defaults.position.y = scaling.window.h - 258

return defaults