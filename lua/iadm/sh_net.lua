local sfs = IADM_SFS
IADM_NET_WRITETABLE = function(tbl)
    local encoded = sfs.encode(tbl)
    local len = #encoded
    net.WriteUInt(len,16)
    net.WriteData(encoded)
end

IADM_NET_READTABLE = function(max_size)
    local len = net.ReadUInt(16)
    local encoded = net.ReadData(len)
    return sfs.decode(encoded,max_size)
end