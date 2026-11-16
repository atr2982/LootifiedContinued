-- Lootified - read-only per-spec stat priority and the relative values used by Percent scoring.
local _, LJ = ...
local L, F = LJ.L, LJ.F

local UI = LJ.UI
local Widgets = LJ.Widgets
local Theme = LJ.Theme
local Util = LJ.Util
local StatPrio = LJ.StatPrio
local C = Theme.COLORS

local View = {}
UI.StatPrioView = View

local ROW_HEIGHT, ROW_STEP, BAR_WIDTH = 17, 18, 110

local function NewRow(view)
    local row = CreateFrame("Frame", nil, view.list)
    row:SetSize(view.width, ROW_HEIGHT)
    row.rank = Widgets.Text(row, "small", C.text4, nil, "RIGHT")
    row.rank:SetWidth(16)
    row.rank:SetPoint("LEFT", 6, 0)
    row.name = Widgets.Text(row, "bodySmall", C.text1)
    row.name:SetPoint("LEFT", row.rank, "RIGHT", 8, 0)
    row.name:SetPoint("RIGHT", -(BAR_WIDTH + 20), 0)
    row.track = row:CreateTexture(nil, "ARTWORK")
    row.track:SetSize(BAR_WIDTH, 4)
    row.track:SetPoint("RIGHT", -10, 0)
    row.track:SetColorTexture(1, 1, 1, 0.08)
    row.bar = row:CreateTexture(nil, "ARTWORK", nil, 1)
    row.bar:SetHeight(4)
    row.bar:SetPoint("LEFT", row.track, "LEFT")
    row.bar:SetColorTexture(Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.9)
    Theme.OnAccent(row, function(r)
        local a = Theme.accent
        r.bar:SetColorTexture(a[1], a[2], a[3], 0.9)
    end)
    return row
end

local function ViewRefresh(view, spec)
    view.spec = spec
    view.label:SetText(Util.Upper(F("Stats for %s", L(spec.name))))
    local top = 24 + 6 + math.ceil(view.text:GetStringHeight()) + 10
    view.list:ClearAllPoints()
    view.list:SetPoint("TOPLEFT", 0, -top)
    local rows, best = StatPrio.Rows(spec), 0
    for _, row in ipairs(rows) do best = math.max(best, row.value) end
    for i, data in ipairs(rows) do
        local row = view.rows[i] or NewRow(view)
        view.rows[i] = row
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_STEP)
        row.rank:SetText(i)
        row.name:SetText(L(data.text))
        row.bar:SetWidth(math.max(1, BAR_WIDTH * data.value / best))
        row:Show()
    end
    for i = #rows + 1, #view.rows do view.rows[i]:Hide() end
    view.list:SetHeight(math.max(ROW_HEIGHT, #rows * ROW_STEP - (ROW_STEP - ROW_HEIGHT)))
    view:SetHeight(top + view.list:GetHeight())
end

function View.Create(parent, width)
    local view = CreateFrame("Frame", nil, parent)
    view:SetWidth(width)
    view.width = width
    view.label = Widgets.Text(view, "label", C.text4)
    view.label:SetPoint("LEFT", view, "TOPLEFT", 0, -12)
    view.label:SetPoint("RIGHT", view, "TOPRIGHT", 0, -12)
    view.text = Widgets.Text(view, "small", C.text2)
    view.text:SetPoint("TOPLEFT", 0, -30)
    view.text:SetWidth(width)
    view.text:SetJustifyH("LEFT")
    view.text:SetWordWrap(true)
    view.text:SetText(L("Recommended stat order for this spec. The bars show the same priorities used to rank gear."))
    view.list = CreateFrame("Frame", nil, view)
    view.list:SetWidth(width)
    view.rows = {}
    view.Refresh = ViewRefresh
    return view
end
