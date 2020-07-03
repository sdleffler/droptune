local prototype = dtrequire("prototype")
local resource = dtrequire("resource")

local ResourcePicker = prototype.new()
do
    function ResourcePicker:init(editor, id, validate, title)
        self.editor = editor
        self.id = id
        self.validate = validate
        self.title = id or title
    end

    local function buildTree(self, Slab, path, table)
        local picked

        for k, v in pairs(table) do
            if type(v) == "table" and v._path then
                if Slab.BeginTree(path .. k, {Label = k}) then
                    v() -- preload the table so we can look inside
                    picked = picked or buildTree(self, Slab, path .. k .. ".", v)
                    Slab.EndTree()
                end
            elseif k ~= "_path" then
                local leafpath = path .. k
                Slab.BeginTree(leafpath, {Label = k, IsLeaf = true})
                if Slab.IsControlClicked() and (not self.validate or self.validate(leafpath)) then
                    picked = picked or leafpath
                end
            end
        end
        
        return picked
    end

    function ResourcePicker:updateUI()
        local Slab = self.editor.Slab

        Slab.BeginWindow(self.id, {Title = "Resources"})
        local picked = buildTree(self, Slab, "", resource.getTable())
        Slab.EndWindow()

        return picked
    end
end

return ResourcePicker