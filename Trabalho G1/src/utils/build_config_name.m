function configName = build_config_name(opts)

    if opts.normalizeData
        normTag = 'norm';
    else
        normTag = 'raw';
    end

    if opts.useMice
        miceTag = 'mice';
    else
        miceTag = 'nomice';
    end

    configName = [normTag '_' miceTag];
end