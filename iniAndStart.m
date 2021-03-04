function initAndStart(id)
    global lastId
    if ~exist(lastId)
        lastId = "";
    end
    if lastId ~= id
        save;
        clear all;
        load;
        clearvars -except id;
        startup;
    end
    if(id == 'aaaZkouska')
        id = 'aaaZkouska';
    elseif(id == 'aaaZkouska2')
        id = 'aaaZkouska2';
    else
        id = 'exp_doubleEC_28_log_nonadapt';
    end
    global lastId
    lastId = id;
    expInit(id);
    metacentrum_task_matlab(id, 'C:\Users\jirir\dp\dp\surrogate-cmaes\exp\experiments', 1);
end