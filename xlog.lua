local xserialize = require("xserialize")

return function(...)
    print(os.date("[%Y-%m-%d %H:%M:%S]=> ", os.time()) .. xserialize(...))
end
