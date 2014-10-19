function conf = rcnn_config(varargin)
% Set up configuration variables.
%   conf = rcnn_config(varargin)
%
%   Each variable is named by a path that identifies a field
%   in the returned conf structure. For example, 'foo.bar'
%   corresponds to conf.foo.bar. You can set configuration
%   variables in 3 ways:
%   1) File: directly editing values in this file
%   2) Per-call: pass an override as an argument to this function
%      E.g., conf = rcnn_config('foo', 'bar');
%   3) Per-session: assign the global variable RCNN_CONFIG_OVERRIDE
%      to a function that returns a conf structure with specific
%      overrides set. This method is persistent until RCNN_CONFIG_OVERRIDE
%      is cleared. 
%      E.g., you could put this code in a function to programmatically
%      override the config.
%
%        global RCNN_CONFIG_OVERRIDE;
%        conf_override.exp_dir = '/path/to/experiment_directory';
%        RCNN_CONFIG_OVERRIDE = @() conf_override;

% AUTORIGHTS
% ---------------------------------------------------------
% Copyright (c) 2014, Ross Girshick
% 
% This file is part of the R-CNN code and is available 
% under the terms of the Simplified BSD License provided in 
% LICENSE. Please retain this notice and LICENSE if you use 
% this file (or any portion of it) in your project.
% ---------------------------------------------------------

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Defaults config (override in rcnn_config_local.m)
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% If you want to override any of these, create a **script** 
% named rcnn_config_local.m and redefine these variables there.

% Experiments directory. The directory under which most outputs
% generated by running this code will go.
p = get_paths();
EXP_DIR = fullfile(p.detection_dir, 'detector');

% Set to false if you do not want to use a GPU.
USE_GPU = true;

% Load local overrides if rccn_config_local.m exists
% See rcnn_config_local.example.m for an example
if exist('rcnn_config_local.m')
  rcnn_config_local;
end


% ~~~~~~~~~~~~~~~~~~~~~~ ADVANCED SETUP BELOW ~~~~~~~~~~~~~~~~~~~~~~
% 
% conf            top-level variables
%
% To set a configuration override file, declare
% the global variable RCNN_CONFIG_OVERRIDE 
% and then set it as a function handle to the
% config override function. E.g.,
%  >> global RCNN_CONFIG_OVERRIDE;
%  >> RCNN_CONFIG_OVERRIDE = @my_rcnn_config;
% In this example, we assume that you have an M-file 
% named my_rcnn_config.m. 
%
% Overrides passed in as arguments have the highest precedence.
% Overrides in the overrides file have second highest precedence,
% but are clobbered by overrides passed in as arguments.
% Settings in this file are clobbered by the previous two.

% Configuration structure
conf = [];

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% 
% Persistent and per-call overrides
%
% Check for an override configuration file
assert_not_in_parallel_worker();
global RCNN_CONFIG_OVERRIDE;
if ~isempty(RCNN_CONFIG_OVERRIDE)
  conf = RCNN_CONFIG_OVERRIDE();
end

% Clobber with overrides passed in as arguments
for i = 1:2:length(varargin)
  key = varargin{i};
  val = varargin{i+1};
  eval(['conf.' key ' = val;']);
end
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

conf = cv(conf, 'use_gpu', USE_GPU);
conf = cv(conf, 'exp_dir', EXP_DIR);
conf = cv(conf, 'sub_dir', '');
conf = cv(conf, 'cache_dir', fullfile(conf.exp_dir, conf.sub_dir, filesep));

exists_or_mkdir(conf.cache_dir);


% -------------------------------------------------------------------
% Helper functions
% -------------------------------------------------------------------

% -------------------------------------------------------------------
% Does nothing if conf.key exists, otherwise sets conf.key to val
function conf = cv(conf, key, val)
try
  eval(['conf.' key ';']);
catch
  eval(['conf.' key ' = val;']);
end


% -------------------------------------------------------------------
% Throw an error if this function is called from inside a matlabpool
% worker.
function assert_not_in_parallel_worker()
% Matlab does not support accessing global variables from
% parallel workers. The result of reading a global is undefined
% and in practice has odd and inconsistent behavoir. 
% The configuraton override mechanism relies on a global
% variable. To avoid hard-to-find bugs, we make sure that
% rcnn_config cannot be called from a parallel worker.

t = [];
if usejava('jvm')
  try
    t = getCurrentTask();
  catch 
  end
end

if ~isempty(t)
  msg = ['rcnn_config() cannot be called from a parallel worker ' ...
         '(or startup.m did not run -- did you run matlab from the ' ...
         'root of the rcnn installation directory?'];
  error(msg);
end
