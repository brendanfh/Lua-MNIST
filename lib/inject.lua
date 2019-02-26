local inject = {}

function inject:Setup()
    self.binds = {}
    self.statics = {}
end

function inject:Bind(name, cls)
    self.binds[name] = {
        kind = "class";
        obj = cls;
    }
end

function inject:BindStatic(name, cls)
    self.binds[name] = {
        kind = "static";
        obj = cls;
    }
end

function inject:Get(name, ...)
    local bind = self.binds[name]

    if bind.kind == "class" then
        return bind.obj(...)
    elseif bind.kind == "static" then
        if self.statics[bind.obj] then
            return self.statics[bind.obj]
        else
            local o = bind.obj(...)
            self.statics[bind.obj] = o
            return o
        end
    end

    error("Unknown dependency")
end

_G.inject = inject
