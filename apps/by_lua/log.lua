local system_conf                   = require "config.init"
local stats_main_conf               = system_conf.stats_main_conf
local stats_match_conf              = system_conf.stats_match_conf
local stats_match_switch            = system_conf.stats_match_switch

local status                        = ngx.var.status or 499
local uri                           = ngx.var.uri or '-'
local host                          = ngx.var.host or 'host'
local request_time                  = ngx.var.request_time or 0
local upstream_response_time        = ngx.var.upstream_response_time or 0
local bytes_sent                    = ngx.var.bytes_sent or 0
local request                       = ngx.var.request or '-'

local stats = require "apps.lib.stats"
local stats_center = stats:new(uri,status,request_time,upstream_response_time,bytes_sent)

local body = stats_center:read_body()
body = body .. ' ' .. request

-- 正则匹配统计
if stats_match_switch then
	-- 获取正则特殊定制统计
	for i, v in ipairs(stats_match_conf) do
		if v['switch'] and host == v['host'] then
			stats_center:incr_match(body,v['match'])
			break
		end
	end
end

stats_center:gateway_request_all()