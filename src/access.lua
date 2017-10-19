
-- Copyright 2017 Vladimir Gagin

--    Licensed under the Apache License, Version 2.0 (the "License");
--    you may not use this file except in compliance with the License.
--    You may obtain a copy of the License at

--        http://www.apache.org/licenses/LICENSE-2.0

--    Unless required by applicable law or agreed to in writing, software
--    distributed under the License is distributed on an "AS IS" BASIS,
--    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--    See the License for the specific language governing permissions and
-- limitations under the License.

local _M = {}
local cjson = require "cjson.safe"
local pl_stringx = require "pl.stringx"
local http = require "resty.http"
local crypto = require "crypto"
local singletons = require "kong.singletons"
local xconf
-- local cache = singletons.cache

local OAUTH_CALLBACK = "^%s/oauth2/callback(/?(\\?[^\\s]*)*)$"

function _M.run(conf)
     -- Check if the API has a request_path and if it's being invoked with the path resolver
    local path_prefix = ""
    xconf = conf

    if ngx.ctx.api.uris ~= nil then
        for index, value in ipairs(ngx.ctx.api.uris) do
            if pl_stringx.startswith(ngx.var.request_uri, value) then
                path_prefix = value
                break
            end
        end

        if pl_stringx.endswith(path_prefix, "/") then
            path_prefix = path_prefix:sub(1, path_prefix:len() - 1)
        end

    end
    
    -- local access_token = ngx.var.cookie_token
    local access_token = ngx.req.get_headers()["Authorization"]
    if access_token ~= nil then
        ngx.log(ngx.WARN, "TOKEN: " .. access_token)
        access_token = string.match( access_token, 'Bearer (%w+)')
    else
        ngx.log(ngx.WARN, "NO TOKEN")
    end    

    if access_token == nil then
        ngx.status = 401
        ngx.say("not authorized")
        ngx.exit(ngx.HTTP_OK)
        return
    end    

    ngx.log(ngx.WARN, "TOKEN: " .. access_token)
    ngx.log(ngx.WARN, "load_token: " .. check_token(access_token).body)
    
    local cache_token, err = singletons.cache:get('token.' .. access_token, nil, load_token, access_token)

    -- check token
    if not err then
        -- redirect to auth if user result is invalid not 200
        if cache_token == nil then
            ngx.status = 401
            ngx.say("Error token valiation")
            ngx.exit(ngx.HTTP_OK)
            return
        end

        ngx.log(ngx.WARN, "cache_token: " .. cache_token)
        local json = cjson.decode(cache_token)
        if ngx.time() - json.time > 30 then
            singletons.cache:invalidate('token.' .. access_token)
            ngx.log(ngx.WARN, "token is to old")
            local cache_token, err = singletons.cache:get('token.' .. access_token, nil, load_token, access_token)
        end

        for i, key in ipairs(conf.user_keys) do
            ngx.header["X-Oauth-".. key] = json.info[key]
        end
        ngx.header["X-Oauth-Token"] = access_token

    else
        ngx.status = 500
        ngx.say(err)
        ngx.exit(ngx.HTTP_OK)
        return
    end

end

function check_token( token )
    local httpc = http:new()
    local res, err = httpc:request_uri(xconf.token_url, {
        method = "GET",
        ssl_verify = false,
        headers = {
            ["Authorization"] = "Bearer " .. token,
        }
    })

    return res, err

end

function load_token(token)
    local res, err = check_token(token)
    local rescache = {}

    if err or res.status ~= 200 then
        return nil
    else
        rescache['time'] = ngx.time()
        rescache['info'] = cjson.decode(res.body)
        return cjson.encode(rescache)
    end
end


return _M
