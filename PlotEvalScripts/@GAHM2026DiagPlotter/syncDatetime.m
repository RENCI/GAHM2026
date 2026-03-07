function [idxA, idxB] = syncDatetime(~, A, B)
% syncDatetime  Find matching datetime indices between two struct arrays.
%
%   [idxA, idxB] = obj.syncDatetime(A, B)
%
%   A and B are struct arrays with a .datetime field.
%   Returns index vectors idxA and idxB such that
%     A(idxA(k)).datetime == B(idxB(k)).datetime   for all k.
%
%   Example:
%     [ig, ia] = obj.syncDatetime(GAHM_out, ASWIP);
%     X = [GAHM_out(ig).Rmax34];    % extract synced GAHM values
%     Y = [ASWIP(ia).Rmax34];       % extract synced ASWIP values

    isync = 0;
    idxA = [];
    idxB = [];

    for i = 1:length(A)
        for j = 1:length(B)
            if A(i).datetime == B(j).datetime
                isync = isync + 1;
                idxA(isync) = i; %#ok<AGROW>
                idxB(isync) = j; %#ok<AGROW>
            end
        end
    end

end