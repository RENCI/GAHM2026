function [wafData, wafMetadata] = loadWAFData(outputType, fileName)
% loadWAFData Load output-specific wind adjustment factor data.
    arguments
        outputType (1,1) string
        fileName (1,1) string
    end

    wafMetadata = [];
    if outputType == "grid"
        [wafData, wafMetadata] = readgeoraster(fileName);
    elseif outputType == "points"
        fileVariables = string({whos("-file", fileName).name});
        if ~any(fileVariables == "WAF_points")
            error("GAHM2026:MissingWafPoints", ...
                "The point WAF file must contain a variable named WAF_points.");
        end
        wafFile = load(fileName, "WAF_points");
        wafData = wafFile.WAF_points;
    else
        error("GAHM2026:InvalidOutputType", ...
            "Output type must be either grid or points when WAF is enabled.");
    end
end
