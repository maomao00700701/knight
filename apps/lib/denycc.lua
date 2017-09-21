-- Copyright (C) 2016-2017 WeiHang Song (Jakin)
-- 基于Redis实现ip频率限制的集群cc防御


local _M = {
    _VERSION = '0.01'
}

local system_conf            = require "config.init"
local redis_conf             = system_conf.redisConf
local denycc_rate_conf       = system_conf.denycc_rate_conf
local ngxshared              = ngx.shared
local denycc_conf            = ngxshared.denycc_conf
local cache                  = require "apps.resty.cache"

_M.denycc_run = function()
    local denycc_rate_ts         = denycc_conf:get('denycc_rate_ts') or denycc_rate_conf.ts
    local denycc_rate_request    = denycc_conf:get('denycc_rate_request') or denycc_rate_conf.request
    local ip_parser              = require "apps.lib.ip_parser"
    local ip                     = ip_parser:get()
    local ts                     = math.ceil(ngx.time()/denycc_rate_ts)
    local limit                  = 'LIMIT:' .. ip .. ':' .. ts

    local red = cache:new(redis_conf)
    local ok, err = red:connectdb()
    if not ok then
        return 
    end

    local hit, err = red.redis:incr(limit)

    if hit == 1 then
        red.redis:expire(limit,denycc_rate_ts)
    end
    
    red:keepalivedb()

    if hit >= denycc_rate_request then
        ngx.header["Content-Type"] = "text/html; charset=UTF-8"
        ngx.header["NGX-DENYCC-HIT"] = hit
        ngx.exit(429)
        ngx.log(ngx.ERR, "denycc ip: ", ip)
        return
    else
        --ngx.header["Content-Type"] = "text/html; charset=UTF-8"
        --ngx.header["NGX-DENYCC-HIT"] = hit
        --ngx.say(limit .. ":" .. hit)    
    end
end


return _M