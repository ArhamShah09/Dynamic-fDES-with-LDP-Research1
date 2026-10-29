function rrMs = cleanRR(rr, minRRms, maxRRms)
%CLEANRR Convert RR values to milliseconds and retain plausible intervals.

rr = rr(:);
rr = rr(isfinite(rr));
if isempty(rr)
    error('cleanRR:EmptyInput', 'The RR vector has no finite values.');
end

% Values below 20 are interpreted as seconds; otherwise as milliseconds.
if median(rr) < 20
    rrMs = rr * 1000;
else
    rrMs = rr;
end
rrMs = rrMs(rrMs > minRRms & rrMs < maxRRms);
if numel(rrMs) < 2
    error('cleanRR:TooShort', 'Fewer than two plausible RR intervals remain.');
end
end
