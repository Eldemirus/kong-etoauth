package = "kong-etoauth"
version = "0.1-1"
source = {
   url = "git://github.com/eldemirus/"
}
description = {
   summary = "external oauth token check plugin",
   homepage = "http://github.com/eldemirus",
   license = "Apache 2.0"
}
dependencies = {
  "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
    ["kong.plugins.etoauth.access"] = "src/access.lua",
    ["kong.plugins.etoauth.handler"] = "src/handler.lua",
    ["kong.plugins.etoauth.schema"] = "src/schema.lua"
   }
}
