exp_id = 'aaaZkouska';
exp_description = 'Fixed (non-adaptive) DTS-CMA-ES based on exp_doubleEC_26_1model, albeit testing multiple GP kernels. Enable logging of populations.';

% BBOB/COCO framework settings

bbobParams = { ...
  'dimensions',         { 2 }, ... % alternative: { 2, 4, 8, 16 }
  'functions',          num2cell(1), ...      % all functions: num2cell(1:24)
  'opt_function',       { @opt_s_cmaes }, ...
  'instances',          { [11] }, ...         % default is [1:5, 41:50]
  'maxfunevals',        { '250 * dim' }, ...
  'resume',             { true }, ...
  'progressLog',        { true }, ...
};

% Surrogate manager parameters

surrogateParams = { ...
  'evoControl',         { 'doubletrained' }, ...    % 'none', 'individual', 'generation', 'restricted'
  'observers',          { {'DTScreenStatistics', 'DTFileStatistics'} },... % logging observers
  'modelType',          { 'gpnn' }, ...               % 'gp', 'rf', 'bbob'
  'updaterType',        { 'constant' }, ...         % OrigRatioUpdater
  'evoControlMaxDoubleTrainIterations', { 1 }, ...
  'evoControlPreSampleSize',       { 0.75 }, ...       % {0.25, 0.5, 0.75}, will be multip. by lambda
  'evoControlOrigPointsRoundFcn',  { 'ceil' }, ...  % 'ceil', 'getProbNumber'
  'evoControlTrainRange',          { 10 }, ...      % will be multip. by sigma
  'evoControlTrainNArchivePoints', { '15*dim' },... % will be myeval()'ed, 'nRequired', 'nEvaluated', 'lambda', 'dim' can be used
  'evoControlSampleRange',         { 1 }, ...       % will be multip. by sigma
  'evoControlOrigGenerations',     { [] }, ...
  'evoControlModelGenerations',    { [] }, ...
  'evoControlValidatePoints',      { [] }, ...
  'evoControlRestrictedParam',     { 0.05 }, ...
};

% Model parameters

modelParams = { ...
  'hypOptions',         { ...
      struct( ...             % LIN
        'covFcn',             { '{@covPoly, ''eye'', 1}' }, ...
        'hyp',                { struct('lik', log(0.01), ...
                                       'cov', { log([0.1 1]) }) }, ...
        'hypRestartSigma',    { diag([2 5 5 0.01]) } ...
      ), ...
      struct( ...             % QUAD
        'covFcn',             { '{@covPoly, ''eye'', 2}' }, ...
        'hyp',                { struct('lik', log(0.01), ...
                                       'cov', { log([0.1 1]) }) }, ...
        'hypRestartSigma',    { diag([2 5 5 0.01]) } ...
      ), ...
      struct( ...             % SE
        'covFcn',             { '@covSEiso' }, ...
        'hyp',                { struct('lik', log(0.01), ...
                                       'cov', { log([0.5 2]) } ) }, ...
        'hypRestartSigma',    { diag([2 5 5 0.01]) } ...
      ), ...
      struct( ...             % MATERN5
        'covFcn',             { '{@covMaterniso, 5}' }, ...
        'hyp',                { struct('lik', log(0.01), ...
                                       'cov', { log([0.5 2]) } ) }, ...
        'hypRestartSigma',    { diag([2 5 5 0.01]) } ...
      ), ...
      struct( ...             % RQ
        'covFcn',             { '@covRQiso' }, ...
        'hyp',                { struct('lik', log(0.01), ...
                                       'cov', { log([0.5 2 0.1]) } ) }, ...
        'hypRestartSigma',    { diag([2 5 5 5 0.01]) } ...
      ), ...
      struct( ...             % NN (ARCSIN)
        'covFcn',             { '@covNNone' }, ...
        'hyp',                { struct('lik', log(0.01), ...
                                       'cov', { log([0.5 2]) } ) }, ...
        'hypRestartSigma',    { diag([2 5 5 0.01]) } ...
      ), ...
      struct( ...             % ADD
        'covFcn',             { '{@covADD, {[1 max(2, ceil(obj.dim/2))], @covSEisoU}}' }, ...
        'hyp',                { struct('lik', log(0.1), ...
                                       'cov', { [log(0.5) 1 1] } ) }, ...
        'hypRestartSigma',    { 'diag([2 2 * ones(1, obj.dim) 2 2 0.01])' } ...
      ), ...
      struct( ...             % SE + QUAD
        'covFcn',             { '{@covSum, {@covSEiso, {@covPoly, ''eye'', 2}}}' }, ...
        'hyp',                { struct('lik', log(0.01), ...
                                       'cov', { log([0.5 2 0.1 1]) } ) }, ...
        'hypRestartSigma',    { diag([2 2 2 2 2 0.01]) } ...
      ), ...
      struct( ...             % GIBBS
       'covFcn',              { '{@covSEvlen, {@meanSum, {@meanLinear, @meanConst}}}' }, ...
       'hyp',                 { struct('lik', log(0.01), ...
                                       'cov', { '[zeros(1, obj.dim) 0.5 log([2])]' } ) }, ...
       'hypRestartSigma',     { 'diag([2 10 * ones(1, obj.dim) 10 5 0.01])' } ...
      ), ...
  }, ...
  'restartDesign',      { 'normal' }, ...
  'meanFcn',            { 'meanConst' }, ...
  'trainAlgorithm',     { 'fmincon' }, ...
  'predictionType',     { 'poi' }, ...
  'useShift',           { false }, ...
  'normalizeY',         { true }, ...
  'trainsetType'        { 'nearest' }, ...
  'trainRange',         { 4 }, ...
  'trainsetSizeMax'     { '20*dim' }, ...
  'nRestarts',          { 2 }, ...
  'cmaesCheckBounds',   { false }, ...
};


% CMA-ES parameters

cmaesParams = { ...
  'PopSize',            { '(8+floor(6*log(N)))' }, ...        %, '(8 + floor(6*log(N)))'};
  'Restarts',           { 50 }, ...
  'DispModulo',         { 0 }, ...
};

logDir = '/storage/brno2/home/ruzicji6/public';