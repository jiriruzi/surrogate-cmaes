function getDataMetaFeatures(folder, varargin)
% getDataMetaFeatures(dataname) calculates metafeatures on large set of
% data
% 
% Input:
%   folder   - data input folder
%   settings - pairs of property (string) and value, or struct with 
%              properties as fields:
%     'Design' - sampling design of source data (use only if data was 
%                generated by using one) | {'lhs', 'ilhs', 'lhsnorm'}
%     'MetaInput' - input sets for metafeature calculation | {'archive',
%                   'test', 'train', 'test+train'}
%
% See Also:
%   getMetaFeatures

  
  if nargin < 1
    help getDataMetaFeatures
    return
  end
  
  % parse settings
  settings = settings2struct(varargin{:});
  design = defopts(settings, 'Design', '');
  
  % data may be divided between multiple folders
  if (~iscell(folder))
    folder = {folder};
  end
  
  % get data according to design
  if isempty(design)
    getRegularDataMetaFeatures(folder, settings);
  else
    getDesignedDataMetaFeatures(folder, design);
  end
  
end

function getRegularDataMetaFeatures(folder, settings)
% get metafeatures from data in folder without specified generation design
  
  listFeatures = {'basic', ...
                'cm_angle', ...
                'cm_convexity', ...
                'cm_gradhomo', ...
                'cmaes', ...
                'dispersion', ...
                'ela_distribution', ...
                'ela_levelset', ...
                'ela_metamodel', ...
                'gcm', ...
                'infocontent', ...
                'linear_model', ...
                'nearest_better', ...
                'pca' ...
               };

  % parse settings
  opts.lb = defopts(settings, 'lb', '-5*ones(1, dim)');
  opts.ub = defopts(settings, 'ub', ' 5*ones(1, dim)');
  opts.features = defopts(settings, 'features', listFeatures);
  opts.metaInput = defopts(settings, 'MetaInput', {'archive'});

  % gather all MAT-files
  datalist = {};
  for f = 1:length(folder)
    actualDataList = searchFile(folder{f}, '*.mat');
    if numel(actualDataList) > 0
      datalist(end+1 : end+length(actualDataList)) = actualDataList;
    end
  end

  % create feature folder
  % TODO: adaptively create folders according to the original file
  % structure
  outputFolder = [folder{1}, '_fts']; 
  [~, ~] = mkdir(outputFolder);
  
  % list through all data
  for dat = 1:length(datalist)
    % load data
    warning('off', 'MATLAB:load:variableNotFound')
    data = load(datalist{dat}, '-mat', 'ds');
    warning('on', 'MATLAB:load:variableNotFound')
    if all(isfield(data, {'ds'}))
      
      % get dataset size (function * dimension * (instances * models))
      [fun, dim, instMod] = size(data.ds);
      
      res = cell(fun, dim, instMod);
      % function loop
      for f = 1:fun
        % dimension loop
        for d = 1:dim
          % instance * model loop
          for im = 1:instMod
            % metafeature calculation for different generations
            res{f, d, im} = getSingleDataMF(data.ds{f, d, im}, opts);
          end
        end
      end
      
      % save data
      [~, filename] = fileparts(datalist{dat});
      % TODO: check uniqueness of output filenames
      outputFile = fullfile(outputFolder, [filename, '_fts.mat']);
      save(outputFile, 'res')
    else
      fprintf('Variable ''ds'' not found in %s.\n', datalist{dat})
    end
    
  end

end

function res = getSingleDataMF(ds, opts)
% calculate metafeatures in different generations

  % get generations
  generations = ds.generations;
  nGen = numel(generations);
  
  % generation loop
  for g = 1:nGen
    % CMA-ES feature settings
    if any(strcmp(opts.features, 'cmaes'))
      opts.cmaes.cma_cov = ds.BDs{g}*ds.BDs{g}';
      opts.cmaes.cma_evopath_c = ds.pcs{g};
      opts.cmaes.cma_evopath_s = ds.pss{g};
      opts.cmaes.cma_generation = generations(g);
      opts.cmaes.cma_mean = ds.means{g};
      opts.cmaes.cma_restart = ds.iruns(g);
      opts.cmaes.cma_step_size = ds.sigmas{g};
    end
    
    % meta input set loop
    for iSet = 1:numel(opts.metaInput)
      % get correct input
      switch opts.metaInput{iSet}
        case 'archive'
          X = ds.archive.X(ds.archive.gens < generations(g), :);
          y = ds.archive.y(ds.archive.gens < generations(g), :);
        case 'test'
          X = ds.testSetX{g};
          y = NaN(size(X, 1), 1);
        case 'train'
          [X, y] = getTrainData(ds);
        case {'test+train', 'train+test'}
          [X, y] = getTrainData(ds);
          X = [X; ds.testSetX{g}];
          y = [y; NaN(size(X, 1), 1)];
      end
      % calculate metafeatures
      [res.ft(g).(opts.metaInput{iSet}), values{iSet}] = getMetaFeatures(X, y, opts);
    end
    res.values(:, g) = cell2mat(values');
  end
      
end

function [X, y] = getTrainData(ds)
% get training data for model

%TODO:
  X = [];
  y = [];
end
  
function getDesignedDataMetaFeatures(folder, design)
% get metafeatures from data in folder generated through specified design

  funIds = 1:24;
  dims = [2, 5, 10];
  instIds = [1:5 41:50];
  Ns = {'50 * dim'};
%   design = {'lhs'};

%   exppath = fullfile('exp', 'experiments');
%   input_path = fullfile(exppath, 'data_metalearn');
  input_path = folder;
  in_fname_template = strjoin({'data_metalearn_', ...
    '%dD_', ...
    'f%d_', ...
    'inst%d_', ...
    'N%d_', ...
    'design-%s.mat'}, '');

  output_path = [folder, '_fts'];
  [~, ~] = mkdir(output_path);
  out_fname_template = 'metafeatures_N-%s_design-%s.mat';

  t0 = tic;
  for N_cell = Ns
    for design_cell = design
      des = design_cell{:};
      % 3d cell for results; N and design type will be distinguished by file name
      mfts = cell(max(dims), max(funIds), max(instIds));

      for dim = dims
        for funId = funIds
          for instId = instIds
            % debug
            fprintf('%dD, f%d, inst%d ...\n', dim, funId, instId);

            % load input data
            N = myeval(N_cell{:});
            in_fname = sprintf(in_fname_template, dim, funId, instId, N, des);
            in_fname = fullfile(input_path, sprintf('%dD', dim), in_fname);
            data = load(in_fname);

            % compute metafeatures
            opts.lb = -5 * ones(1, dim);
            opts.ub = 5 * ones(1, dim);
            opts.features = {'basic', 'cm_angle', 'cm_convexity', ...
                     'cm_gradhomo', 'dispersion', 'ela_distribution', ...
                     'ela_levelset', 'ela_metamodel', 'infocontent', ...
                     'nearest_better', 'pca'};
            [res.ft, res.values] = getMetaFeatures(data.X', data.Y', opts);
            mfts{dim, funId, instId} = res;

            % debug
            fprintf('Elapsed time: %.2f sec.\n', (tic - t0) / 1e6);
          end
        end
      end % dim loop

      % save results
      Nstr = strrep(N_cell{:}, ' * ', '');
      out_fname = sprintf(out_fname_template, Nstr, des);
      out_fname = fullfile(output_path, out_fname);
      save(out_fname, 'funIds', 'dims', 'instIds', 'Ns', 'design', 'mfts');
    end
  end
  
end
