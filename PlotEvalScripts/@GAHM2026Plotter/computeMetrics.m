function metrics = computeMetrics(obj, X, Y, varName)
% computeMetrics  Compute objective comparison metrics between two datasets.
%
%   metrics = obj.computeMetrics(X, Y)
%   metrics = obj.computeMetrics(X, Y, varName)
%
%   Computes bias, RMSE, MAE, correlation, R-squared, and scatter index
%   between the paired arrays X (observed / dataset A) and Y (modeled /
%   dataset B).  Pairs where either value is NaN or zero are removed
%   before computation (zeros are treated as missing, consistent with
%   scatterCompare).
%
%   Inputs:
%     X, Y    - numeric arrays of the same size (observed vs modeled)
%     varName - (optional) string label for the variable; default 'Variable'
%
%   Output:
%     metrics - struct with fields:
%       N       - number of valid pairs
%       bias    - mean(Y - X)
%       RMSE    - root-mean-square error
%       MAE     - mean absolute error
%       R       - Pearson correlation coefficient
%       R2      - R squared
%       SI      - scatter index (RMSE / mean(X))
%       varName - variable label string
%
%   If opts.scatter.csvFile is set (non-empty string), a row is appended
%   to that CSV file.  A header line is written when the file does not yet
%   exist.
%
%   A summary is printed to the command window.
%
% EXAMPLES
%   metrics = obj.computeMetrics(obs, mod);
%   metrics = obj.computeMetrics(obs, mod, 'Wind Speed (kts)');
%
%   % Write metrics to CSV (set the option first):
%   obj.setOpts('scatter', 'csvFile', 'metrics.csv');
%   m1 = obj.computeMetrics(obsV, modV, 'Vmax');
%   m2 = obj.computeMetrics(obsP, modP, 'Pc');

    % Default variable name
    if nargin < 4 || isempty(varName)
        varName = "Variable";
    end

    % Flatten to column vectors
    X = X(:);
    Y = Y(:);

    % Remove pairs where either value is NaN or zero
    bad = isnan(X) | isnan(Y) | (X == 0) | (Y == 0);
    X(bad) = [];
    Y(bad) = [];

    N = numel(X);

    if N > 0
        diff_YX = Y - X;
        bias = mean(diff_YX);
        RMSE = sqrt(mean(diff_YX.^2));
        MAE = mean(abs(diff_YX));
        Rmat = corrcoef(X, Y);
        R = Rmat(1, 2);
        R2 = R^2;
        meanX = mean(X);
        if meanX ~= 0
            SI = RMSE / meanX;
        else
            SI = NaN;
        end
    else
        bias = NaN;
        RMSE = NaN;
        MAE = NaN;
        R = NaN;
        R2 = NaN;
        SI = NaN;
    end

    % Build output struct
    metrics.N = N;
    metrics.bias = bias;
    metrics.RMSE = RMSE;
    metrics.MAE = MAE;
    metrics.R = R;
    metrics.R2 = R2;
    metrics.SI = SI;
    metrics.varName = varName;

    % Print summary
    fprintf('\n--- computeMetrics: %s ---\n', varName);
    fprintf('  N    = %d\n', N);
    fprintf('  Bias = %.4f\n', bias);
    fprintf('  RMSE = %.4f\n', RMSE);
    fprintf('  MAE  = %.4f\n', MAE);
    fprintf('  R    = %.4f\n', R);
    fprintf('  R2   = %.4f\n', R2);
    fprintf('  SI   = %.4f\n', SI);
    fprintf('------------------------------\n');

    % CSV export
    if isfield(obj.Opts, 'scatter') && isfield(obj.Opts.scatter, 'csvFile') ...
            && ~isempty(obj.Opts.scatter.csvFile)
        csvFile = obj.Opts.scatter.csvFile;
        writeHeader = ~isfile(csvFile);
        fid = fopen(csvFile, 'a');
        if fid ~= -1
            if writeHeader
                fprintf(fid, 'Variable,N,Bias,RMSE,MAE,R,R2,SI\n');
            end
            fprintf(fid, '%s,%d,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\n', ...
                varName, N, bias, RMSE, MAE, R, R2, SI);
            fclose(fid);
        else
            warning("computeMetrics:csvOpen", ...
                "Could not open CSV file for writing: %s", csvFile);
        end
    end

end
