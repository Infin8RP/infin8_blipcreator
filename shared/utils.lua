function GetLicenseIdentifier(playerSrc)
    local identifiers = GetPlayerIdentifiers(playerSrc)
    for _, identifier in ipairs(identifiers) do
        if string.find(identifier, 'license:') then
            return identifier
        end
    end
    return nil
end
