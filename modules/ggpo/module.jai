GGPO_SUCCEEDED :: (result: GGPOErrorCode) -> bool #expand
{
    return result == .GGPO_ERRORCODE_SUCCESS; 
}

#scope_module

#if OS == .WINDOWS {
    #load "windows.jai";
    #library,system,link_always "winmm";
}
