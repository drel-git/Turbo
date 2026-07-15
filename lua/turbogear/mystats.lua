-- TurboGear/mystats.lua
-- Project Lazarus #mystats helper.
--
-- Do not scrape the LargeDialogWindow/STML body here. Reading that window body
-- crashed this client during testing, so TurboGear uses Inventory Stats labels
-- for machine-readable live stats instead.

local M = {}
local ok_mq, mq = pcall(require, 'mq')

function M.probe(opts)
    print("[TurboGear #mystats Probe] Disabled: reading the #mystats/STML body can crash this client.")
    print("[TurboGear #mystats Probe] Use /tgear invstats open for the safe Inventory Stats named-label probe.")
    return 0
end

function M.open()
    if ok_mq and mq and mq.cmd then
        mq.cmd('/say #mystats')
        print("[TurboGear] Sent /say #mystats. TurboGear will not scrape the #mystats body.")
        return true
    end
    print("[TurboGear] Type #mystats in chat to open the Project Lazarus stats window.")
    print("[TurboGear] TurboGear will not scrape the #mystats body.")
    return false
end

return M
