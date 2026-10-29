function features = compute_features(rrMs, C)
%COMPUTE_FEATURES Calculate all features at the selected main parameters.

features.tDES = tDES(rrMs, C.mainRms);
features.symDES = symDES(rrMs, C.mainNBins, C.symbolRangeMs);
features.triFDES = tri_fDES(rrMs, C.mainRms);
features.expFDES = exp_fDES(rrMs, C.mainAlphaPerSecond);
features.pNN50 = pNN50(rrMs);
profile = laplace_des_profile(rrMs, C);
features.LDP_scaleMs = profile.scaleMs;
features.LDP_auc = profile.auc;
features.LDP_halfZ = profile.halfZ;
features.LDP_halfDms = profile.halfDms;
features.LDP_decayRate = profile.decayRate;
features.LDP_heterogeneity = profile.heterogeneity;
end
