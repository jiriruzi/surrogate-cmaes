classdef DoubleTrainedEC < EvolutionControl
  properties 
    model
  end
  
  methods 
    function obj = DoubleTrainedEC()
    % constructor
      obj.model = [];
    end
    
    function [fitness_raw, arx, arxvalid, arz, counteval, lambda, archive, surrogateStats] = runGeneration(obj, cmaesState, surrogateOpts, sampleOpts, archive, counteval, varargin)
    % Run one generation of double trained evolution control
      
      fitness_raw = [];
      arx = [];
      arxvalid = [];
      arz = [];
      surrogateStats = NaN(1, 2);
      
      % extract cmaes state variables
      xmean = cmaesState.xmean;
      sigma = cmaesState.sigma;
      lambda = cmaesState.lambda;
      BD = cmaesState.BD;
      dim = cmaesState.dim;
      countiter = cmaesState.countiter;
      
      obj.model = ModelFactory.createModel(surrogateOpts.modelType, surrogateOpts.modelOpts, xmean');

      if (isempty(obj.model))
        % model could not be created :( use the standard CMA-ES
        return;
      end
      
      minTrainSize = obj.model.getNTrainData();

      nArchivePoints = myeval(surrogateOpts.evoControlTrainNArchivePoints);
      [xTrain, yTrain] = archive.getDataNearPoint(nArchivePoints, ...
          xmean', surrogateOpts.evoControlTrainRange, sigma, BD);
      
      [fitness_raw, arx, arxvalid, arz, archive, counteval, xTrain, yTrain] = ...
        presample(minTrainSize, cmaesState, surrogateOpts, sampleOpts, archive, counteval, xTrain, yTrain, varargin{:});

      nPresampledPoints = size(arxvalid, 2);
      if (nPresampledPoints == lambda)
        return
      end

      % train the model 
      obj.model = obj.model.train(xTrain, yTrain, cmaesState, sampleOpts);

      nLambdaRest = lambda - nPresampledPoints;
      
      if (~obj.model.isTrained())
        return
      end
      
      % sample new points
      [xExtend, xExtendValid, zExtend] = ...
          sampleCmaesNoFitness(sigma, nLambdaRest, cmaesState, sampleOpts);
      [modelOutput, fvalExtend] = obj.model.getModelOutput(xExtend');
      % choose rho points with low confidence to reevaluate
      if any(strcmpi(obj.model.predictionType, {'sd2', 'poi', 'ei'}))
        % higher criterion is better (sd2, poi, ei)
        [~, pointID] = sort(modelOutput, 'descend');
      else
        % lower criterion is better (fvalues, lcb, fpoi, fei)
        [~, pointID] = sort(modelOutput, 'ascend');
      end
      reevalID = false(1, nLambdaRest);
      assert(surrogateOpts.evoControlRestrictedParam >= 0 && surrogateOpts.evoControlRestrictedParam <= 1, 'evoControlRestrictedParam out of bounds [0,1]');
      nLambdaRest = ceil(nLambdaRest * surrogateOpts.evoControlRestrictedParam);
      reevalID(pointID(1:nLambdaRest)) = true;
      xToReeval = xExtend(:, reevalID);
      xToReevalValid = xExtendValid(:, reevalID);
      zToReeval = zExtend(:, reevalID);

      % original-evaluate the chosen points
      [yNew, xNew, xNewValid, zNew, counteval] = ...
          sampleCmaesOnlyFitness(xToReeval, xToReevalValid, zToReeval, sigma, nLambdaRest, counteval, cmaesState, sampleOpts, varargin{:});
      fprintf('counteval: %d\n', counteval)
      % update the Archive
      archive = archive.save(xNewValid', yNew', countiter);
      % the obj.models' dataset will be supplemented with this
      % new points during the next training using all the xTrain
      % calculate the models' precision
      yPredict = obj.model.predict(xNewValid');
      kendall = corr(yPredict, yNew', 'type', 'Kendall');
      rmse = sqrt(sum((yPredict' - yNew).^2))/length(yNew);
      fprintf('  model-gener.: %d preSamples, reevaluated %d pts, test RMSE = %f, Kendl. corr = %f.\n', nPresampledPoints, nLambdaRest, rmse, kendall);
      surrogateStats = [rmse, kendall];

      % TODO: control the evolution process according to the model
      % Use Spearman? Pearson?
      % precision -> next TODO

      if ~all(reevalID)
        xTrain = [xTrain; xNewValid'];
        yTrain = [yTrain; yNew'];
        % train the model again
        retrainedModel = obj.model.train(xTrain, yTrain, cmaesState, sampleOpts);
        if (retrainedModel.isTrained())
          yNewRestricted = retrainedModel.predict((xExtend(:, ~reevalID))');
          surrogateStats = getModelStatistics(retrainedModel, cmaesState, surrogateOpts, sampleOpts, counteval);
        else
          % use values estimated by the old model
          fprintf('Restricted: The new model could not be trained, using the not-retrained model.\n');
          yNewRestricted = fvalExtend(~reevalID);
          surrogateStats = getModelStatistics(obj.model, cmaesState, surrogateOpts, sampleOpts, counteval);
        end
        yNew = [yNew, yNewRestricted'];
        xNew = [xNew, xExtend(:, ~reevalID)];
        xNewValid = [xNewValid, xExtendValid(:, ~reevalID)];
        zNew = [zNew, zExtend(:, ~reevalID)];

        % shift the f-values:
        %   if the model predictions are better than the best original value
        %   in the model's dataset, shift ALL (!) function values
        %   Note: - all values have to be shifted in order to preserve predicted
        %           ordering of values
        %         - small constant is added because of the rounding errors
        %           when numbers of different orders of magnitude are summed
        fminDataset = min(obj.model.dataset.y);
        fminModel = min(yNewRestricted);
        diff = max(fminDataset - fminModel, 0);
        fitness_raw = fitness_raw + 1.000001*diff;
        yNew = yNew + 1.000001*diff;
      end
      
      % TODO: count new restrictedParam value
              
      % save the resulting re-evaluated population as the returning parameters
      fitness_raw = [fitness_raw yNew];
      arx = [arx xNew];
      arxvalid = [arxvalid xNewValid];
      arz = [arz zNew];
      
    end
    
  end
  
end

function res=myeval(s)
  if ischar(s)
    res = evalin('caller', s);
  else
    res = s;
  end
end