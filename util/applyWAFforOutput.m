function adjustedVortex = applyWAFforOutput(outputType, wafData, wafMetadata, ...
        vortex, longitude, latitude)
% applyWAFforOutput Apply output-specific WAF while preserving vortex data.
    arguments
        outputType (1,1) string
        wafData
        wafMetadata
        vortex (1,1) struct
        longitude
        latitude
    end

    if outputType == "grid"
        adjustedVelocity = applyWAFfromRaster(wafData, wafMetadata, ...
            vortex, longitude, latitude);
    elseif outputType == "points"
        adjustedVelocity = applyWAFfromPoints(wafData, vortex, longitude, latitude);
    else
        error("GAHM2026:InvalidOutputType", ...
            "Output type must be either grid or points when WAF is enabled.");
    end

    adjustedVortex = vortex;
    adjustedVortex.VelU = adjustedVelocity.VelU;
    adjustedVortex.VelV = adjustedVelocity.VelV;
    if isfield(vortex, "Speed")
        adjustedVortex.Speed = hypot(adjustedVelocity.VelU, adjustedVelocity.VelV);
    end
end
