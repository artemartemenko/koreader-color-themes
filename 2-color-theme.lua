local BD = require("ui/bidi")
local Blitbuffer = require("ffi/blitbuffer")
local Button = require("ui/widget/button")
local ButtonDialog = require("ui/widget/buttondialog")
local ButtonTable = require("ui/widget/buttontable")
local Cache = require("cache")
local DictQuickLookup = require("ui/widget/dictquicklookup")
local Event = require("ui/event")
local FileManager = require("apps/filemanager/filemanager")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local HtmlBoxWidget = require("ui/widget/htmlboxwidget")
local IconWidget = require("ui/widget/iconwidget")
local ImageWidget = require("ui/widget/imagewidget")
local InputText = require("ui/widget/inputtext")
local LineWidget = require("ui/widget/linewidget")
local ReaderFooter = require("apps/reader/modules/readerfooter")
local ReaderHighlight = require("apps/reader/modules/readerhighlight")
local ReaderStyleTweak = require("apps/reader/modules/readerstyletweak")
local ReaderUI = require("apps/reader/readerui")
local RenderImage = require("ui/renderimage")
local RenderText = require("ui/rendertext")
local Screen = require("device").screen
local ScreenSaverWidget = require("ui/widget/screensaverwidget")
local Size = require("ui/size")
local TextBoxWidget = require("ui/widget/textboxwidget")
local TextWidget = require("ui/widget/textwidget")
local ToggleSwitch = require("ui/widget/toggleswitch")
local UIManager = require("ui/uimanager")
local UnderlineContainer = require("ui/widget/container/underlinecontainer")
local VirtualKeyboard = require("ui/widget/virtualkeyboard")
local ffi = require("ffi")
local logger = require("logger")
local userpatch = require("userpatch")
local util = require("util")
local _ = require("gettext")
local T = require("ffi/util").template

local function Setting(name, default)
    local self = {}
    self.get = function()
        local v = G_reader_settings:readSetting(name)
        if v == nil then return default end
        return v
    end
    self.set = function(value) return G_reader_settings:saveSetting(name, value) end
    self.toggle = function() G_reader_settings:toggle(name) end
    return self
end

local ActivePreset = Setting("color_theme_preset", "parchment")
local ActivePresetUI = Setting("color_theme_preset_ui", nil)
local ActivePresetBook = Setting("color_theme_preset_book", nil)
local NightPreset = Setting("color_theme_preset_night", "default_night")
local NightPresetUI = Setting("color_theme_preset_night_ui", nil)
local NightPresetBook = Setting("color_theme_preset_night_book", nil)
local CustomPresets = Setting("color_theme_custom_presets", {})
local DisabledPresets = Setting("color_theme_disabled_presets", {})
local DarkPresets = Setting("color_theme_dark_presets", {
    "default_night",
    "slate",
    "twilight",
    "dim_night",
    "amber_night",
    "ink",
    "mono_dark",
    "stay_with_ukraine",
})


local PRESETS = {
    { key = "white",        label = "Default Day",     bg = "#FFFFFF", fg = "#000000" },
    { key = "paper",        label = "Paper",           bg = "#F2F2F2", fg = "#1A1A1A" },
    { key = "light_gray",   label = "Light Gray",      bg = "#EDEDED", fg = "#4F4F4F" },
    { key = "warm_stone",   label = "Warm Stone",      bg = "#D7D5D3", fg = "#000000" },
    { key = "cream",        label = "Cream",           bg = "#F3EFD8", fg = "#111111" },
    { key = "parchment",    label = "Parchment",       bg = "#EBE0C9", fg = "#2C1A0E" },
    { key = "soft_parchment", label = "Soft Parchment", bg = "#EBE0C9", fg = "#645031" },
    { key = "sepia",        label = "Sepia",           bg = "#F5E6C8", fg = "#2C1A0E" },
    { key = "warm_sepia",   label = "Warm Sepia",      bg = "#E3D1B3", fg = "#422A14" },
    { key = "green_tea",    label = "Green Tea",       bg = "#D4E8D0", fg = "#1A3320" },
    { key = "arctic",       label = "Arctic",          bg = "#E8F0F8", fg = "#0D1B2A" },
    { key = "cool_mist",    label = "Cool Mist",       bg = "#EBEFF5", fg = "#052F75" },

    { key = "default_night", label = "Default Night",  bg = "#000000", fg = "#FFFFFF" },
    { key = "ink",           label = "Ink",            bg = "#050505", fg = "#E0E0E0" },
    { key = "mono_dark",     label = "Mono Dark",      bg = "#1A1A1A", fg = "#F5F5F5" },
    { key = "twilight",      label = "Twilight",       bg = "#282A2C", fg = "#FFFFFF" },
    { key = "dim_night",     label = "Dim Night",      bg = "#121212", fg = "#B0B0B0" },
    { key = "slate",         label = "Slate",          bg = "#2C3E50", fg = "#DCDCDC" },
    { key = "amber_night",   label = "Amber Night",    bg = "#14100A", fg = "#FAD08A" },
    { key = "stay_with_ukraine", label = "Dyakuyu", bg = "#1B305A", fg = "#F3D79A" },
}

local function all_presets()
    local result = {}
    local disabled_map = {}
    for _, k in ipairs(DisabledPresets.get() or {}) do
        disabled_map[k] = true
    end
    for _, p in ipairs(PRESETS) do
        if not disabled_map[p.key] then
            result[p.key] = {
                key = p.key,
                label = p.label,
                bg = p.bg,
                fg = p.fg,
            }
        end
    end

    local custom = CustomPresets.get() or {}
    for _, p in ipairs(custom) do
        result[p.key] = {
            key = p.key,
            label = p.label,
            bg = p.bg,
            fg = p.fg,
        }
    end

    local ordered = {}
    for _, p in ipairs(PRESETS) do
        local v = result[p.key]
        if v then table.insert(ordered, v) end
    end
    for key, p in pairs(result) do
        local is_builtin = false
        for _, bp in ipairs(PRESETS) do
            if bp.key == key then is_builtin = true; break end
        end
        if not is_builtin then
            table.insert(ordered, p)
        end
    end

    return ordered
end

local function presetLabelWithSwatch(p)
    return p.label
end
local function presetByKey(key)
    for _, p in ipairs(all_presets()) do
        if p.key == key then return p end
    end
    return PRESETS[1]
end

local function colorEquals(c1, c2)
    return c1 and c2 and c1:getColorRGB32() == c2:getColorRGB32()
end

local function luminance(color)
    return 0.299 * color:getR() + 0.587 * color:getG() + 0.114 * color:getB()
end

local function contrast(c1, c2)
    return math.abs(luminance(c1) - luminance(c2))
end
local function preset_is_dark(key, bg_hex)
    local dark_map = {}
    for _, k in ipairs(DarkPresets.get() or {}) do
        dark_map[k] = true
    end
    if dark_map[key] ~= nil then
        return dark_map[key]
    end
    local c = Blitbuffer.colorFromString(bg_hex or "#FFFFFF")
    return luminance(c) < 128
end

local function set_preset_dark_flag(key, is_dark)
    local current = DarkPresets.get() or {}
    local map = {}
    for _, k in ipairs(current) do
        map[k] = true
    end
    if is_dark then
        if not map[key] then
            table.insert(current, key)
        end
    else
        local filtered = {}
        for _, k in ipairs(current) do
            if k ~= key then
                table.insert(filtered, k)
            end
        end
        current = filtered
    end
    DarkPresets.set(current)
    G_reader_settings:flush()
end

local function has_document_open()
    return ReaderUI.instance ~= nil and ReaderUI.instance.document ~= nil
end

local function lightenColor(c, amount)
    return Blitbuffer.ColorRGB32(
        math.floor(c:getR() + (255 - c:getR()) * amount),
        math.floor(c:getG() + (255 - c:getG()) * amount),
        math.floor(c:getB() + (255 - c:getB()) * amount)
    )
end

local function colorToHex(c)
    if not c then return "#000000" end
    return string.format("#%02X%02X%02X", c:getR(), c:getG(), c:getB())
end

local function get_dpi_scale()
    local size_scale = math.min(Screen:getWidth(), Screen:getHeight()) * (1 / 600)
    local dpi_scale = Screen:scaleByDPI(1)
    return math.max(0, (math.log((size_scale + dpi_scale) / 2) / 0.69) ^ 2)
end
local DPI_SCALE = get_dpi_scale()
local ICON_MAX_DIM = Screen:scaleBySize(96)

local ImageCache = Cache:new {
    size = 8 * 1024 * 1024,
    avg_itemsize = 64 * 1024,
    enable_eviction_cb = false,
}

local uint8pt = ffi.typeof("uint8_t*")
local P_Color8A = ffi.typeof("Color8A*")
local P_ColorRGB16 = ffi.typeof("ColorRGB16*")
local P_ColorRGB32 = ffi.typeof("ColorRGB32*")

local bg_cached = {
    last_bg_hex = nil,
    last_fg_hex = nil,
    bgcolor = nil,
    fgcolor = nil,
    font_fgcolor = nil,
    bg_hex = "",
    fg_hex = "",
    book_bgcolor = nil,
    book_fgcolor = nil,
    book_font_fgcolor = nil,
    book_bg_hex = "",
    book_fg_hex = "",
}

local function resolveActivePreset(active_setting, night_setting)
    local key = active_setting.get()
    if Screen.night_mode then
        local nk = night_setting.get()
        if nk and nk ~= "" then key = nk end
    end
    return key
end

local function computeColorsForPreset(preset_key)
    local p = presetByKey(preset_key)
    local bg_hex = p.bg or "#FFFFFF"
    local fg_hex = p.fg or "#000000"
    local bg_color = Blitbuffer.colorFromString(bg_hex)
    local font_color = Blitbuffer.colorFromString(fg_hex)
    if Screen.night_mode and Screen.bb and Screen.bb.getInverse and Screen.bb:getInverse() == 1 then
        bg_color = bg_color:invert()
        font_color = font_color:invert()
    end
    local fg_color = Blitbuffer.ColorRGB32(
        bg_color:getR() * 0.6,
        bg_color:getG() * 0.6,
        bg_color:getB() * 0.6
    )
    return bg_hex, fg_hex, bg_color, fg_color, font_color
end

local function recomputeColors()
    local ui_key
    local book_key

    if Screen.night_mode then
        ui_key = NightPresetUI.get()
        if not ui_key or ui_key == "" then
            ui_key = NightPreset.get()
        end

        book_key = NightPresetBook.get()
        if not book_key or book_key == "" then
            book_key = NightPreset.get()
        end
    else
        ui_key = ActivePresetUI.get()
        if not ui_key or ui_key == "" then
            ui_key = ActivePreset.get()
        end

        book_key = ActivePresetBook.get()
        if not book_key or book_key == "" then
            book_key = ActivePreset.get()
        end
    end

    local bg_hex, fg_hex, bg_color, fg_color, font_color = computeColorsForPreset(ui_key)
    bg_cached.bg_hex = bg_hex
    bg_cached.fg_hex = fg_hex
    bg_cached.bgcolor = bg_color
    bg_cached.fgcolor = fg_color
    bg_cached.font_fgcolor = font_color
    bg_cached.last_bg_hex = bg_hex
    bg_cached.last_fg_hex = fg_hex

    local bbg_hex, bfg_hex, bbg_color, bfg_color, bfont_color = computeColorsForPreset(book_key)
    bg_cached.book_bg_hex = bbg_hex
    bg_cached.book_fg_hex = bfg_hex
    bg_cached.book_bgcolor = bbg_color
    bg_cached.book_fgcolor = bfg_color
    bg_cached.book_font_fgcolor = bfont_color
end

recomputeColors()

local function refreshFileManager()
    if FileManager.instance then
        FileManager.instance.file_chooser:updateItems(1, true)
    end
end

local function reloadIcons()
    ImageCache:clear()
    UIManager:broadcastEvent(Event:new("ChangeBackgroundColor"))
end

function ReaderFooter:onRefreshFooterBackground()
    self:refreshFooter(true)
end
local function applyProgressBarTheme()
    if not has_document_open() or not ReaderUI.instance.footer then return end
    local footer = ReaderUI.instance.footer
    if not footer.progress_bar then return end
    footer.progress_bar.fillcolor = bg_cached.book_font_fgcolor
    footer.progress_bar.bgcolor = bg_cached.book_bgcolor
    footer:refreshFooter(true)
end

local function refreshUI()
    recomputeColors()
    refreshFileManager()
    reloadIcons()
    if has_document_open() then
        UIManager:broadcastEvent(Event:new("ApplyStyleSheet"))
        UIManager:broadcastEvent(Event:new("RefreshFooterBackground"))
        applyProgressBarTheme()
    end
    UIManager:setDirty("all", "full")
end

local function create_custom_preset(name, bg_hex, fg_hex, touchmenu_instance)
    local label = util.trim(name or "")
    if label == "" then
        label = _("Custom")
    end
    bg_hex = string.upper(bg_hex)
    fg_hex = string.upper(fg_hex)

    local list = CustomPresets.get() or {}
    local base_key = "custom_" .. label:lower():gsub("%s+", "_"):gsub("[^%w_]", "")
    if base_key == "custom_" then
        base_key = "custom"
    end
    local key = base_key
    local suffix = 1
    local function key_exists(k)
        for _, p in ipairs(list) do
            if p.key == k then return true end
        end
        return false
    end
    while key_exists(key) do
        suffix = suffix + 1
        key = base_key .. "_" .. suffix
    end

    table.insert(list, { key = key, label = label, bg = bg_hex, fg = fg_hex })
    CustomPresets.set(list)
    G_reader_settings:flush()

    return key
end

local function edit_custom_preset(key, name, bg_hex, fg_hex, touchmenu_instance)
    local label = util.trim(name or "")
    if label == "" then
        label = _("Custom")
    end
    bg_hex = string.upper(bg_hex)
    fg_hex = string.upper(fg_hex)

    local list = CustomPresets.get() or {}
    local found = false
    for _, p in ipairs(list) do
        if p.key == key then
            p.label = label
            p.bg = bg_hex
            p.fg = fg_hex
            found = true
            break
        end
    end
    if not found then
        table.insert(list, { key = key, label = label, bg = bg_hex, fg = fg_hex })
    end
    CustomPresets.set(list)
    G_reader_settings:flush()

    return key
end

local function delete_custom_preset(key, touchmenu_instance)
    local list = CustomPresets.get() or {}
    local new_list = {}
    local had_custom = false
    for _, p in ipairs(list) do
        if p.key ~= key then
            table.insert(new_list, p)
        else
            had_custom = true
        end
    end
    CustomPresets.set(new_list)

    local disabled = DisabledPresets.get() or {}
    local already_disabled = false
    for _, k in ipairs(disabled) do
        if k == key then already_disabled = true; break end
    end
    if not already_disabled then
        table.insert(disabled, key)
        DisabledPresets.set(disabled)
    end

    G_reader_settings:flush()

    if ActivePreset.get() == key then
        ActivePreset.set("parchment")
        G_reader_settings:flush()
    end

    refreshUI()
    if touchmenu_instance then touchmenu_instance:updateItems() end
end

local function open_custom_theme_dialog(touchmenu_instance, preset)
    local InputDialog = require("ui/widget/inputdialog")

    local existing_label = (preset and preset.label) or ""
    local existing_bg = (preset and preset.bg) or "#FFFFFF"
    local existing_fg = (preset and preset.fg) or "#000000"

    local function ask_fg(name, bg_hex)
        local dialog
        dialog = InputDialog:new({
            title = _("Custom text color (#RRGGBB)"),
            input = existing_fg or "#000000",
            input_hint = "#000000",
            buttons = {
                {
                    {
                        text = _("Cancel"),
                        callback = function()
                            UIManager:close(dialog)
                        end,
                    },
                    {
                        text = _("Next"),
                        callback = function()
                            local text = util.trim(dialog:getInputText() or "")
                            if text == "" or not text:match("^#%x%x%x%x%x%x$") then
                                return
                            end
                            UIManager:close(dialog)

                            local type_dialog
                            type_dialog = ButtonDialog:new({
                                buttons = {
                                    {
                                        {
                                            text = _("Save as light theme"),
                                            callback = function()
                                                if string.upper(bg_hex) == string.upper(text) then
                                                    return
                                                end
                                                local key
                                                if preset and preset.key then
                                                    key = edit_custom_preset(preset.key, name, bg_hex, text, touchmenu_instance)
                                                else
                                                    key = create_custom_preset(name, bg_hex, text, touchmenu_instance)
                                                end
                                                if key then
                                                    set_preset_dark_flag(key, false)
                                                    ActivePreset.set(key)
                                                    G_reader_settings:flush()
                                                    refreshUI()
                                                    if touchmenu_instance then touchmenu_instance:updateItems() end
                                                end
                                                UIManager:close(type_dialog)
                                            end,
                                        },
                                    },
                                    {
                                        {
                                            text = _("Save as dark theme"),
                                            callback = function()
                                                if string.upper(bg_hex) == string.upper(text) then
                                                    return
                                                end
                                                local key
                                                if preset and preset.key then
                                                    key = edit_custom_preset(preset.key, name, bg_hex, text, touchmenu_instance)
                                                else
                                                    key = create_custom_preset(name, bg_hex, text, touchmenu_instance)
                                                end
                                                if key then
                                                    set_preset_dark_flag(key, true)
                                                    NightPreset.set(key)
                                                    G_reader_settings:flush()
                                                    if Screen.night_mode then
                                                        refreshUI()
                                                    else
                                                        refreshUI()
                                                    end
                                                    if touchmenu_instance then touchmenu_instance:updateItems() end
                                                end
                                                UIManager:close(type_dialog)
                                            end,
                                        },
                                    },
                                    {
                                        {
                                            text = _("Cancel"),
                                            callback = function()
                                                UIManager:close(type_dialog)
                                            end,
                                        },
                                    },
                                },
                                width_factor = 0.6,
                            })
                            UIManager:show(type_dialog)
                        end,
                    },
                },
            },
        })
        UIManager:show(dialog)
        dialog:onShowKeyboard()
    end

    local function ask_bg(name)
        local dialog
        dialog = InputDialog:new({
            title = _("Custom background color (#RRGGBB)"),
            input = existing_bg or "#FFFFFF",
            input_hint = "#FFFFFF",
            buttons = {
                {
                    {
                        text = _("Cancel"),
                        callback = function()
                            UIManager:close(dialog)
                        end,
                    },
                    {
                        text = _("Next"),
                        callback = function()
                            local text = util.trim(dialog:getInputText() or "")
                            if text == "" or not text:match("^#%x%x%x%x%x%x$") then
                                return
                            end
                            UIManager:close(dialog)
                            ask_fg(name, text)
                        end,
                    },
                },
            },
        })
        UIManager:show(dialog)
        dialog:onShowKeyboard()
    end

    local function ask_name()
        local dialog
        local buttons_row = {
            {
                text = _("Cancel"),
                callback = function()
                    UIManager:close(dialog)
                end,
            },
            {
                text = _("Delete"),
                callback = function()
                    UIManager:close(dialog)
                    if preset and preset.key then
                        delete_custom_preset(preset.key, touchmenu_instance)
                    end
                end,
            },
        }
        table.insert(buttons_row, {
            text = _("Next"),
            callback = function()
                local text = util.trim(dialog:getInputText() or "")
                if text == "" then
                    return
                end
                UIManager:close(dialog)
                ask_bg(text)
            end,
        })

        dialog = InputDialog:new({
            title = preset and _("Edit custom theme") or _("New custom theme"),
            input = existing_label,
            input_hint = _("My theme"),
            buttons = { buttons_row },
        })
        UIManager:show(dialog)
        dialog:onShowKeyboard()
    end

    ask_name()
end

local function restore_themes_to_default(touchmenu_instance)
    local dialog
    dialog = ButtonDialog:new({
        buttons = {
            {
                {
                    text = _("Cancel"),
                    callback = function()
                        UIManager:close(dialog)
                    end,
                },
                {
                    text = _("OK"),
                    callback = function()
                        UIManager:close(dialog)
                        local custom = CustomPresets.get() or {}
                        local builtin_keys = {}
                        for _, p in ipairs(PRESETS) do
                            builtin_keys[p.key] = true
                        end
                        local new_custom = {}
                        for _, p in ipairs(custom) do
                            if not builtin_keys[p.key] then
                                table.insert(new_custom, p)
                            end
                        end
                        CustomPresets.set(new_custom)
                        DisabledPresets.set({})
                        ActivePreset.set("white")
                        ActivePresetUI.set("")
                        ActivePresetBook.set("")
                        NightPreset.set("default_night")
                        NightPresetUI.set("")
                        NightPresetBook.set("")
                        DarkPresets.set({
                            "default_night",
                            "slate",
                            "twilight",
                            "dim_night",
                            "amber_night",
                            "ink",
                            "mono_dark",
                            "stay_with_ukraine",
                        })
                        G_reader_settings:flush()
                        refreshUI()
                        if touchmenu_instance then touchmenu_instance:updateItems() end
                    end,
                },
            },
        },
        width_factor = 0.6,
    })
    UIManager:show(dialog)
end

local function getEffectiveUIPreset(is_night)
    if is_night then
        local k = NightPresetUI.get()
        if k and k ~= "" then return k end
        return NightPreset.get()
    else
        local k = ActivePresetUI.get()
        if k and k ~= "" then return k end
        return ActivePreset.get()
    end
end

local function getEffectiveBookPreset(is_night)
    if is_night then
        local k = NightPresetBook.get()
        if k and k ~= "" then return k end
        return NightPreset.get()
    else
        local k = ActivePresetBook.get()
        if k and k ~= "" then return k end
        return ActivePreset.get()
    end
end

local function build_theme_submenu(target, is_night)
    local function get_current_key()
        if target == "ui_day" then
            return getEffectiveUIPreset(false)
        elseif target == "book_day" then
            return getEffectiveBookPreset(false)
        elseif target == "ui_night" then
            return getEffectiveUIPreset(true)
        elseif target == "book_night" then
            return getEffectiveBookPreset(true)
        end
    end

    local function set_current_key(key)
        if target == "ui_day" then
            ActivePresetUI.set(key)
        elseif target == "book_day" then
            ActivePresetBook.set(key)
        elseif target == "ui_night" then
            NightPresetUI.set(key)
        elseif target == "book_night" then
            NightPresetBook.set(key)
        end
        G_reader_settings:flush()
        refreshUI()
    end

    return function()
        local items = {}
        local light_presets = {}
        local dark_presets = {}

        for _, p in ipairs(all_presets()) do
            local bg_hex = p.bg or "#FFFFFF"
            if preset_is_dark(p.key, bg_hex) then
                table.insert(dark_presets, p)
            else
                table.insert(light_presets, p)
            end
        end

        local function label_for_group(is_dark_group)
            local base
            if target == "ui_day" then
                base = _("Day UI")
            elseif target == "book_day" then
                base = _("Day book")
            elseif target == "ui_night" then
                base = _("Night UI")
            elseif target == "book_night" then
                base = _("Night book")
            else
                base = _("Themes")
            end
            local suffix = is_dark_group and _("Dark themes") or _("Light themes")
            return T(_("%1 - %2"), base, suffix)
        end

        local function add_group(is_dark_group, presets)
            if #presets == 0 then return end

            table.insert(items, {
                text = label_for_group(is_dark_group),
                keep_menu_open = true,
                enabled_func = function() return false end,
            })

            for _, p in ipairs(presets) do
                local lp = p
                table.insert(items, {
                    text = presetLabelWithSwatch(lp),
                    checked_func = function()
                        return get_current_key() == lp.key
                    end,
                    callback = function(touchmenu_instance)
                        set_current_key(lp.key)
                        if touchmenu_instance then touchmenu_instance:updateItems() end
                    end,
                    keep_menu_open = false,
                    hold_callback = function(touchmenu_instance)
                        if lp.key == "white" or lp.key == "default_night" then return end
                        open_custom_theme_dialog(touchmenu_instance, lp)
                    end,
                })
            end
        end

        if is_night then
            add_group(true, dark_presets)
            add_group(false, light_presets)
        else
            add_group(false, light_presets)
            add_group(true, dark_presets)
        end

        return items
    end
end

local function color_theme_ui_day_menu()
    return {
        text_func = function()
            local ui_day = presetByKey(getEffectiveUIPreset(false)).label
            return T(_("Day UI: %1"), ui_day)
        end,
        sub_item_table_func = build_theme_submenu("ui_day", false),
    }
end

local function color_theme_book_day_menu()
    return {
        text_func = function()
            local book_day = presetByKey(getEffectiveBookPreset(false)).label
            return T(_("Day book: %1"), book_day)
        end,
        sub_item_table_func = build_theme_submenu("book_day", false),
    }
end

local function color_theme_ui_night_menu()
    return {
        text_func = function()
            local ui_night = presetByKey(getEffectiveUIPreset(true)).label
            return T(_("Night UI: %1"), ui_night)
        end,
        sub_item_table_func = build_theme_submenu("ui_night", true),
    }
end

local function color_theme_book_night_menu()
    return {
        text_func = function()
            local book_night = presetByKey(getEffectiveBookPreset(true)).label
            return T(_("Night book: %1"), book_night)
        end,
        sub_item_table_func = build_theme_submenu("book_night", true),
    }
end

local function color_theme_menu()
    return {
        text_func = function()
            return _("Themes")
        end,
        sub_item_table_func = function()
            local items = {}

            table.insert(items, color_theme_ui_day_menu())
            table.insert(items, color_theme_book_day_menu())
            table.insert(items, color_theme_ui_night_menu())
            table.insert(items, color_theme_book_night_menu())

            table.insert(items, {
                text = "----------------------------",
                keep_menu_open = true,
                enabled_func = function() return false end,
            })

            table.insert(items, {
                text = _("Add theme…"),
                callback = function(touchmenu_instance)
                    open_custom_theme_dialog(touchmenu_instance)
                end,
                keep_menu_open = true,
            })

            table.insert(items, {
                text = _("Restore themes to default"),
                callback = function(touchmenu_instance)
                    restore_themes_to_default(touchmenu_instance)
                end,
                keep_menu_open = true,
            })

            return items
        end,
    }
end

local FileManagerMenu = require("apps/filemanager/filemanagermenu")
local ReaderMenu = require("apps/reader/modules/readermenu")

local function patch_menu(menu, order)
    table.insert(order.setting, "----------------------------")
    table.insert(order.setting, "color_theme")
    menu.menu_items.color_theme = color_theme_menu()
end

local original_UIManager_ToggleNightMode = UIManager.ToggleNightMode
function UIManager:ToggleNightMode()
    original_UIManager_ToggleNightMode(self)
    refreshUI()
end

local original_UIManager_SetNightMode = UIManager.SetNightMode
function UIManager:SetNightMode(night_mode)
    original_UIManager_SetNightMode(self, night_mode)
    refreshUI()
end

local original_FileManagerMenu_setUpdateItemTable = FileManagerMenu.setUpdateItemTable
function FileManagerMenu:setUpdateItemTable()
    patch_menu(self, require("ui/elements/filemanager_menu_order"))
    original_FileManagerMenu_setUpdateItemTable(self)
end

local original_ReaderMenu_setUpdateItemTable = ReaderMenu.setUpdateItemTable
function ReaderMenu:setUpdateItemTable()
    patch_menu(self, require("ui/elements/reader_menu_order"))
    original_ReaderMenu_setUpdateItemTable(self)
end

local EXCLUSION_COLOR = Blitbuffer.colorFromString("#DAAAAD")
local EXCLUSION_COLOR_RGB32 = EXCLUSION_COLOR:getColorRGB32()

local function is_excluded(color)
    return color and color:getColorRGB32() == EXCLUSION_COLOR_RGB32
end

local original_FrameContainer_paintTo = FrameContainer.paintTo
function FrameContainer:paintTo(bb, x, y)
    local original_background = self.background
    local original_color = self.color
    if original_background then
        if self.use_book_background then
            self.background = bg_cached.book_bgcolor
        elseif not is_excluded(original_background) then
            self.background = bg_cached.bgcolor
        else
            self.background = self.original_background or Blitbuffer.COLOR_WHITE
        end
    end
    original_FrameContainer_paintTo(self, bb, x, y)
    self.background = original_background
    self.color = original_color
end

local original_ReaderFooter_updateFooterContainer = ReaderFooter.updateFooterContainer
function ReaderFooter:updateFooterContainer()
    original_ReaderFooter_updateFooterContainer(self)
    if self.footer_content and self.footer_content.background then
        self.footer_content.use_book_background = true
    end
end

local original_ReaderFooter_init = ReaderFooter.init
function ReaderFooter:init()
    original_ReaderFooter_init(self)
    if self.footer_content and self.footer_content.background then
        self.footer_content.use_book_background = true
    end
    if self.progress_bar then
        self.progress_bar.fillcolor = bg_cached.book_font_fgcolor
        self.progress_bar.bgcolor = bg_cached.book_bgcolor
    end
    if self.footer_text then
        self.footer_text.original_fgcolor = bg_cached.book_font_fgcolor
        self.footer_text.fgcolor = EXCLUSION_COLOR
    end
end

local original_ScreenSaverWidget_init = ScreenSaverWidget.init
function ScreenSaverWidget:init()
    original_ScreenSaverWidget_init(self)
    self[1].original_background = self.background
    self[1].background = EXCLUSION_COLOR
end

local function fillRGB(bb, bbtype, v)
    if bb:getInverse() == 1 then v = v:invert() end
    if bbtype == Blitbuffer.TYPE_BBRGB32 then
        local src = v:getColorRGB32()
        local p = ffi.cast(P_ColorRGB32, bb.data)
        for i = 1, bb.pixel_stride * bb.h do p[0] = src; p = p + 1 end
    elseif bbtype == Blitbuffer.TYPE_BBRGB16 then
        local src = v:getColorRGB16()
        local p = ffi.cast(P_ColorRGB16, bb.data)
        for i = 1, bb.pixel_stride * bb.h do p[0] = src; p = p + 1 end
    elseif bbtype == Blitbuffer.TYPE_BB8A then
        local src = v:getColor8A()
        local p = ffi.cast(P_Color8A, bb.data)
        for i = 1, bb.pixel_stride * bb.h do p[0] = src; p = p + 1 end
    else
        local p = ffi.cast(uint8pt, bb.data)
        ffi.fill(p, bb.stride * bb.h, v.alpha)
    end
end

function ImageWidget:_loadfile()
    local DocumentRegistry = require("document/documentregistry")
    if not DocumentRegistry:isImageFile(self.file) then
        error("Image file type not supported.")
        return
    end
    local width, height
    if self.scale_factor == nil and self.stretch_limit_percentage == nil then
        width, height = self.width, self.height
    end
    local hash = "image|" .. self.file .. "|" .. tostring(width) .. "|" .. tostring(height) .. "|" .. (self.alpha and "alpha" or "flat")
    local scale_for_dpi_here = false
    if self.scale_for_dpi and DPI_SCALE ~= 1 and not self.scale_factor then
        scale_for_dpi_here = true
        hash = hash .. "|d"
        self.already_scaled_for_dpi = true
    end
    local cached = ImageCache:check(hash)
    if cached then
        self._bb = cached.bb
        self._bb_disposable = false
        self._is_straight_alpha = cached.is_straight_alpha
    else
        if util.getFileNameSuffix(self.file) == "svg" then
            local zoom = scale_for_dpi_here and DPI_SCALE or nil
            if not zoom and self.scale_factor == 0 then width, height = self.width, self.height end
            self._bb, self._is_straight_alpha = RenderImage:renderSVGImageFile(self.file, width, height, zoom)
            if not self._bb then
                logger.warn("ImageWidget: Failed to render SVG image file:", self.file)
                self._bb = RenderImage:renderCheckerboard(width, height, Screen.bb:getType())
                self._is_straight_alpha = false
            end
        else
            self._bb = RenderImage:renderImageFile(self.file, false, width, height)
            if not self._bb then
                logger.warn("ImageWidget: Failed to render image file:", self.file)
                self._bb = RenderImage:renderCheckerboard(width, height, Screen.bb:getType())
                self._is_straight_alpha = false
            end
            if scale_for_dpi_here then
                local bb_w, bb_h = self._bb:getWidth(), self._bb:getHeight()
                self._bb = RenderImage:scaleBlitBuffer(self._bb, math.floor(bb_w * DPI_SCALE), math.floor(bb_h * DPI_SCALE))
            end
        end

        if self.is_icon then
            if not self.alpha then
                local bbtype = self._bb:getType()
                if bbtype == Blitbuffer.TYPE_BB8A or bbtype == Blitbuffer.TYPE_BBRGB32 then
                    local w = self.width or self._bb.w
                    local h = self.height or self._bb.h
                    if w <= ICON_MAX_DIM and h <= ICON_MAX_DIM then
                        local icon_bb = Blitbuffer.new(self._bb.w, self._bb.h, Screen.bb:getType())
                        if bg_cached.bgcolor then fillRGB(icon_bb, Screen.bb:getType(), bg_cached.bgcolor) end
                        local mask_bb = Blitbuffer.new(self._bb.w, self._bb.h, Blitbuffer.TYPE_BB8)
                        mask_bb:fill(Blitbuffer.Color8(0xFF))
                        if self._is_straight_alpha then
                            mask_bb:alphablitFrom(self._bb, 0, 0, 0, 0, mask_bb.w, mask_bb.h)
                        else
                            mask_bb:pmulalphablitFrom(self._bb, 0, 0, 0, 0, mask_bb.w, mask_bb.h)
                        end
                        mask_bb:invertRect(0, 0, mask_bb.w, mask_bb.h)
                        icon_bb:colorblitFromRGB32(mask_bb, 0, 0, 0, 0, icon_bb.w, icon_bb.h, bg_cached.font_fgcolor)
                        mask_bb:free()
                        self._unflattened = self._bb
                        self._bb = icon_bb
                        self._is_straight_alpha = nil
                    end
                end
            end
        end

        if not self.file_do_cache then
            self._bb_disposable = true
        else
            self._bb_disposable = false
            cached = { bb = self._bb, is_straight_alpha = self._is_straight_alpha }
            ImageCache:insert(hash, cached, tonumber(cached.bb.stride) * cached.bb.h)
        end
    end
end

function ImageWidget:paintTo(bb, x, y)
    if self.hide then return end
    local size = self:getSize()
    if not self.dimen then
        self.dimen = Geom:new({ x = x, y = y, w = size.w, h = size.h })
    else
        self.dimen.x, self.dimen.y = x, y
    end
    logger.dbg("blitFrom", x, y, self._offset_x, self._offset_y, size.w, size.h)
    local do_alpha = (self.alpha == true) and self._bb and (self._bb:getType() == Blitbuffer.TYPE_BB8A or self._bb:getType() == Blitbuffer.TYPE_BBRGB32)
    if do_alpha then
        if self._is_straight_alpha then
            if Screen.sw_dithering and not self.is_icon then bb:ditheralphablitFrom(self._bb, x, y, self._offset_x, self._offset_y, size.w, size.h)
            else bb:alphablitFrom(self._bb, x, y, self._offset_x, self._offset_y, size.w, size.h) end
        else
            if Screen.sw_dithering and not self.is_icon then bb:ditherpmulalphablitFrom(self._bb, x, y, self._offset_x, self._offset_y, size.w, size.h)
            else bb:pmulalphablitFrom(self._bb, x, y, self._offset_x, self._offset_y, size.w, size.h) end
        end
    else
        if Screen.sw_dithering and not self.is_icon then bb:ditherblitFrom(self._bb, x, y, self._offset_x, self._offset_y, size.w, size.h)
        else bb:blitFrom(self._bb, x, y, self._offset_x, self._offset_y, size.w, size.h) end
    end
    if self.invert then bb:invertRect(x, y, size.w, size.h) end
    if self.dim and self._unflattened then
        local icon_bb = Blitbuffer.new(self._unflattened.w, self._unflattened.h, Blitbuffer.TYPE_BB8)
        icon_bb:fill(Blitbuffer.Color8(0xFF))
        icon_bb:alphablitFrom(self._unflattened, 0, 0, 0, 0, icon_bb.w, icon_bb.h)
        icon_bb:invertRect(0, 0, icon_bb.w, icon_bb.h)
        local fgcolor = Blitbuffer.COLOR_DARK_GRAY
        if Screen.night_mode and Screen.bb and Screen.bb.getInverse and Screen.bb:getInverse() == 1 then
            fgcolor = fgcolor:invert()
        end
        bb:colorblitFromRGB32(icon_bb, x, y, self._offset_x, self._offset_y, size.w, size.h, fgcolor)
        icon_bb:free()
    end
    if Screen.night_mode and self.original_in_nightmode and not self.is_icon then
        bb:invertRect(x, y, size.w, size.h)
    end
end

function IconWidget:onChangeBackgroundColor()
    self:free()
    self:init()
end

function UnderlineContainer:paintTo(bb, x, y)
    local container_size = self:getSize()
    if not self.dimen then self.dimen = Geom:new({ x = x, y = y, w = container_size.w, h = container_size.h }) else self.dimen.x, self.dimen.y = x, y end
    local line_width = self.line_width or self.dimen.w
    local line_x = BD.mirroredUILayout() and (x + self.dimen.w - line_width) or x
    local content_size = self[1]:getSize()
    local p_y = y
    if self.vertical_align == "center" then p_y = math.floor((container_size.h - content_size.h) / 2) + y
    elseif self.vertical_align == "bottom" then p_y = (container_size.h - content_size.h) + y end
    self[1]:paintTo(bb, x, p_y)
    if not colorEquals(self.color, Blitbuffer.COLOR_WHITE) then
        bb:paintRect(line_x, y + container_size.h - self.linesize, line_width, self.linesize, self.color)
    end
end

local original_TextBoxWidget_renderText = TextBoxWidget._renderText
function TextBoxWidget:_renderText(start_row_idx, end_row_idx)
    local ob, of = self.bgcolor, self.fgcolor
    if not is_excluded(ob) then self.bgcolor = bg_cached.bgcolor end
    self.fgcolor = bg_cached.font_fgcolor
    original_TextBoxWidget_renderText(self, start_row_idx, end_row_idx)
    self.bgcolor, self.fgcolor = ob, of
end

local original_LineWidget_paintTo = LineWidget.paintTo
function LineWidget:paintTo(bb, x, y)
    local old = self.background
    self.background = (self.background == Blitbuffer.COLOR_WHITE) and bg_cached.bgcolor or bg_cached.bgcolor:invert()
    original_LineWidget_paintTo(self, bb, x, y)
    self.background = old
end

local original_InputText_initTextBox = InputText.initTextBox
function InputText:initTextBox(text, char_added)
    original_InputText_initTextBox(self, text, char_added)
    self.focused_color = bg_cached.bgcolor:invert()
    self.unfocused_color = Blitbuffer.ColorRGB32(self.focused_color:getR() * 0.5, self.focused_color:getG() * 0.5, self.focused_color:getB() * 0.5)
    self._frame_textwidget.color = self.focused and self.focused_color or self.unfocused_color
end

function InputText:unfocus()
    self.focused = false
    self.text_widget:unfocus()
    self._frame_textwidget.color = self.unfocused_color
end

function InputText:focus()
    self.focused = true
    self.text_widget:focus()
    self._frame_textwidget.color = self.focused_color
end

local original_HtmlBoxWidget_render = HtmlBoxWidget._render
function HtmlBoxWidget:_render()
    original_HtmlBoxWidget_render(self)
    local bg_hex = bg_cached.bg_hex
    if bg_hex ~= "#FFFFFF" and bg_hex ~= "#000000" then
        UIManager:setDirty(self.dialog or "all", function() return "flashui", self.dimen end)
    end
end

local original_DictQuickLookup_getHtmlDictionaryCss = DictQuickLookup.getHtmlDictionaryCss
function DictQuickLookup:getHtmlDictionaryCss()
    local css = original_DictQuickLookup_getHtmlDictionaryCss(self)
    local bg_hex = colorToHex(bg_cached.book_bgcolor or Blitbuffer.colorFromString(bg_cached.book_bg_hex))
    local fg_hex = colorToHex(bg_cached.book_font_fgcolor or Blitbuffer.colorFromString(bg_cached.book_fg_hex))
    css = css .. string.format("\nbody { background-color: %s; color: %s; }\n", bg_hex, fg_hex)
    return css
end

function ToggleSwitch:update()
    self.fgcolor = bg_cached.fgcolor
    self.bgcolor = bg_cached.bgcolor
    local pos = self.position
    for i = 1, #self.toggle_content do
        for j = 1, #self.toggle_content[i] do
            local cell = self.toggle_content[i][j]
            if pos == (i - 1) * self.n_pos + j then
                cell.color = self.fgcolor
                cell.original_background = self.fgcolor
                cell.background = EXCLUSION_COLOR
                cell[1][1].fgcolor = Blitbuffer.COLOR_WHITE
            else
                cell.color = self.bgcolor
                cell.background = self.bgcolor
                cell[1][1].fgcolor = Blitbuffer.COLOR_BLACK
            end
        end
    end
end

function Button:_doFeedbackHighlight()
    if self.text then
        if self[1].radius == nil then
            self[1].radius = Size.radius.button
            self[1].original_background = bg_cached.bgcolor:invert()
            self[1].background = EXCLUSION_COLOR
            self.label_widget.fgcolor = self.label_widget.fgcolor:invert()
        else self[1].invert = true end
        UIManager:widgetRepaint(self[1], self[1].dimen.x, self[1].dimen.y)
    else
        self[1].invert = true
        UIManager:widgetInvert(self[1], self[1].dimen.x, self[1].dimen.y)
    end
    UIManager:setDirty(nil, "fast", self[1].dimen)
end

local original_ReaderStyleTweak_getCssText = ReaderStyleTweak.getCssText
function ReaderStyleTweak:getCssText()
    local css = original_ReaderStyleTweak_getCssText(self)
    local bg_hex = colorToHex(bg_cached.book_bgcolor or Blitbuffer.colorFromString(bg_cached.book_bg_hex))
    local fg_hex = colorToHex(bg_cached.book_font_fgcolor or Blitbuffer.colorFromString(bg_cached.book_fg_hex))
    css = string.format("body { background-color: %s !important; color: %s !important; }\n", bg_hex, fg_hex) .. css
    return util.trim(css)
end

local MIN_KEY_BORDER_CONTRAST = 5
local original_VirtualKeyboard_addKeys = VirtualKeyboard.addKeys
function VirtualKeyboard:addKeys()
    original_VirtualKeyboard_addKeys(self)
    local border_color = bg_cached.fgcolor
    if contrast(border_color, bg_cached.bgcolor) < MIN_KEY_BORDER_CONTRAST then border_color = Blitbuffer.COLOR_DARK_GRAY end
    local keyboard_frame = self[1][1]
    if G_reader_settings:nilOrTrue("keyboard_key_border") then
        keyboard_frame.original_background = border_color
        keyboard_frame.background = EXCLUSION_COLOR
    end
end

local original_CalendarWeek_update, original_CalendarDayView_generateSpan, original_BookDailyItem_init
userpatch.registerPatchPluginFunc("statistics", function()
    local CalendarView = require("calendarview")
    if not CalendarView then return end
    local CalendarWeek = userpatch.getUpValue(CalendarView._populateItems, "CalendarWeek")
    if CalendarWeek then
        if not original_CalendarWeek_update then original_CalendarWeek_update = CalendarWeek.update end
        function CalendarWeek:update()
            original_CalendarWeek_update(self)
            local overlaps = self[1][1]
            local span_index = 2
            for col, day_books in ipairs(self.days_books) do
                for _, book in ipairs(day_books) do
                    if book and book.start_day == col then
                        local span_w = overlaps[span_index][1]
                        span_index = span_index + 1
                        span_w.original_background = span_w.background
                        span_w.background = EXCLUSION_COLOR
                    end
                end
            end
        end
    end
    local CalendarDayView = userpatch.getUpValue(CalendarView._populateItems, "CalendarDayView")
    if CalendarDayView then
        if not original_CalendarDayView_generateSpan then original_CalendarDayView_generateSpan = CalendarDayView.generateSpan end
        function CalendarDayView:generateSpan(start, finish, bgcolor, fgcolor, title)
            local span = original_CalendarDayView_generateSpan(self, start, finish, bgcolor, fgcolor, title)
            if span then
                span.original_background = span.background
                span.background = EXCLUSION_COLOR
            end
            return span
        end
        local BookDailyItem = userpatch.getUpValue(CalendarDayView._populateBooks, "BookDailyItem")
        if BookDailyItem then
            if not original_BookDailyItem_init then original_BookDailyItem_init = BookDailyItem.init end
            function BookDailyItem:init()
                original_BookDailyItem_init(self)
                local span = self[1] and self[1][1] and self[1][1][1] and self[1][1][1][3] and self[1][1][1][3][1]
                if span then
                    span.original_background = span.background
                    span.background = EXCLUSION_COLOR
                end
            end
        end
    end
end)

function ReaderHighlight:showHighlightColorDialog(caller_callback, curr_color)
    local dialog
    local buttons = {}
    for i, v in ipairs(self.highlight_colors) do
        local color_name, color = unpack(v)
        local ok, orig_bg = pcall(function() return self:getHighlightColor(color) end)
        local orig_background = (ok and orig_bg) and orig_bg or nil
        buttons[i] = { {
            text = color ~= curr_color and color_name or color_name .. "  ✓",
            menu_style = true,
            original_background = orig_background,
            background = orig_background and EXCLUSION_COLOR or nil,
            callback = function()
                if color ~= curr_color then caller_callback(color) end
                UIManager:close(dialog)
            end,
        } }
    end
    dialog = ButtonDialog:new({ buttons = buttons, width_factor = 0.4, colorful = true, dithered = true })
    UIManager:show(dialog)
end

local original_ButtonTable_init = ButtonTable.init
function ButtonTable:init()
    original_ButtonTable_init(self)
    for i = 1, #self.buttons_layout do
        for j = 1, #self.buttons_layout[i] do
            local btn_entry = self.buttons[i][j]
            local frame = self.buttons_layout[i][j][1]
            if btn_entry and frame and btn_entry.original_background then
                frame.original_background = btn_entry.original_background
            end
        end
    end
end

local original_TextWidget_paintTo = TextWidget.paintTo
function TextWidget:paintTo(bb, x, y)
    local original_fgcolor = self.fgcolor
    if is_excluded(original_fgcolor) then
        self.fgcolor = self.original_fgcolor or Blitbuffer.COLOR_BLACK
    elseif colorEquals(original_fgcolor, Blitbuffer.COLOR_DARK_GRAY) then
        self.fgcolor = lightenColor(bg_cached.font_fgcolor, 0.5)
        if contrast(self.fgcolor, bg_cached.font_fgcolor) < 10 then self.fgcolor = Blitbuffer.COLOR_DARK_GRAY end
    else
        self.fgcolor = bg_cached.font_fgcolor
    end

    if not Screen:isColorEnabled() then
        original_TextWidget_paintTo(self, bb, x, y)
        self.fgcolor = original_fgcolor
        return
    end

    self:updateSize()
    if self._is_empty then self.fgcolor = original_fgcolor; return end

    if not self.use_xtext then
        RenderText:renderUtf8Text(bb, x, y + self._baseline_h, self.face, self._text_to_draw, true, self.bold, self.fgcolor, self._length)
        self.fgcolor = original_fgcolor
        return
    end

    if not self._xshaping then
        self._xshaping = self._xtext:shapeLine(self._shape_start, self._shape_end, self._shape_idx_to_substitute_with_ellipsis)
    end
    local text_width = bb:getWidth() - x
    if self.max_width and self.max_width < text_width then text_width = self.max_width end
    local pen_x = 0
    local baseline = self.forced_baseline or self._baseline_h
    for i, xglyph in ipairs(self._xshaping) do
        if pen_x >= text_width then break end
        local face = self.face.getFallbackFont(xglyph.font_num)
        local glyph = RenderText:getGlyphByIndex(face, xglyph.glyph, self.bold)
        bb:colorblitFromRGB32(
            glyph.bb,
            x + pen_x + glyph.l + xglyph.x_offset,
            y + baseline - glyph.t - xglyph.y_offset,
            0, 0, glyph.bb:getWidth(), glyph.bb:getHeight(),
            self.fgcolor)
        pen_x = pen_x + xglyph.x_advance
    end
    self.fgcolor = original_fgcolor
end

require("logger").info("2-color-theme: loaded (background + font + presets)")