% cwc.m
%
% Implementation of the cluster worker controller.
%
% Version 1
% 2/27/2011
% Terry Ferrett

classdef cwc < wc
    
    properties
        nodes
        maxWorkers
        workers
        workerPath % path to worker script
        workerScript
        bashScriptPath
        cfp % config file path
        cmlRoot
    end
    
    % Derived properties
    properties
        inPath    % Path to input
        outPath  % Path to results
    end
    
    properties (Access=private)
        wrkCnt
    end
    
    
    methods
        function obj = cwc(cmlRoot, cfpIn, workerScript)
            % 1. Read configuration file name.
            obj.cfp = cfpIn;
            
            % 2. Read input and output paths from configuration file.
            heading = '[Paths]';
            key = 'InputPath';
            out = util.fp(obj.cfp, heading, key);
            obj.inPath = out{1}{1};
            
            heading = '[Paths]';
            key = 'OutputPath';
            out = util.fp(obj.cfp, heading, key);
            obj.outPath = out{1}{1};
            
            % 4. Read active nodes and max workers per node
            %      from configuration file.
            heading = '[Hosts]';
            key = 'host';
            out = util.fp(obj.cfp, heading, key);
            numHosts = length(out);
            for k = 1:numHosts,
                obj.nodes{k} = out{k}{1};
                obj.maxWorkers(k) = str2num(out{k}{2});
            end
            
            obj.cmlRoot = cmlRoot;
            obj.workerScript = workerScript;
            obj.bashScriptPath = [cmlRoot '/srv'];
            
            % Change the home directory to /rhome - the
            %  mount point for home directories on the cluster.
            [ignore pathTemp] = strtok(cmlRoot, '/');
            obj.workerPath = ['/rhome' pathTemp '/srv' '/wrk'];
            
            obj.wrkCnt = 0;
            
            % Initialize worker array
            obj.workers = cWrk.empty(1,0);
        end
    end
    
    
    methods
        function wSta(obj, hostname)
            % Inputs
            %  hostname - node hostname, e.g., node01
            %  wNum - unique integer identifying the worker.
            %
            % Execution steps
            % Start a single worker on a single node.
            % 1. Connect to node
            % 2. Start worker
            %   Inputs: unique ID (integer counter)
            % 3. Return process ID
            
            wNum_str = int2str(obj.wrkCnt);
            
            % Form the command string.
            cmd_str = [obj.bashScriptPath, '/start_worker.sh'];
            
            cmd_str = [cmd_str, ' ',...
                hostname, ' ',...
                obj.workerPath, ' ',...
                obj.workerScript, ' ',...
                int2str(obj.wrkCnt)];
            
            [stat pid] = system(cmd_str);
            % Create worker object from node name and
            newWrkObj = cWrk(hostname, pid, obj.wrkCnt);
            
            % Add worker object to worker array.
            obj.workers(end+1) = newWrkObj;
            
            % Increment worker counter
            obj.wrkCnt = obj.wrkCnt + 1;
        end
        
        function cSta(obj)
            % Loop over all active nodes
            % For all active nodes,
            %   start max_workers
            num_nodes = length(obj.nodes);
            for k = 1:num_nodes,
                for l = 1:obj.maxWorkers(k),
                    wSta(obj, obj.nodes{k});
                end
            end
        end
        
        function wSto(obj, wNum)
            % Iterate over worker array and locate worker
            %  having ID 'wNum'
            numWorkers = length(obj.workers);
            
            tempWrk = [];
            for k = 1:numWorkers,
                if obj.workers(k).wrkCnt == wNum,
                    tempWrk = obj.workers(k);
                    break;
                end
            end
            
            if isempty(tempWrk)
                sprintf('Worker %d not found. \n', wNum);
                return;
            end
            
            % Stop this worker.
            wNum_str = int2str(obj.wrkCnt);
            % Form the command string.
            cmd_str = [obj.bashScriptPath, '/stop_worker.sh'];
            
            cmd_str = [cmd_str, ' ',...
                tempWrk.hostname, ' ',...
                tempWrk.pid];
            
            [stat] = system(cmd_str);
            
            
            % Remove worker from array.
            workTmp = obj.workers(1:k-1);
            workTmp = [workTmp obj.workers(k+1:end)];
            obj.workers = workTmp;
        end
        
        function cSto(obj)
            % Loop over all active nodes
            % For all active nodes,
            %   start max_workers
            num_workers = length(obj.workers);
            for k = 1:num_workers,
                wSto(obj, obj.workers(1).wrkCnt);
            end
        end
        
        function status(obj)
        end
        
    end
end
