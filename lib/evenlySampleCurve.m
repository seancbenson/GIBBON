function [Vg] = evenlySampleCurve(varargin)

% function [Vg] = evenlySampleCurve(V,n,interpPar,closeLoopOpt)
% ------------------------------------------------------------------------
% 
% The evenlySampleCurve function samples a curve evenly in n points. The
% curve is parameterized using curve distance and can be closed loop if
% closeLoopOpt==1 (default=0). The resampling is performed using
% interpolation based on the method specified by interpPar. 
% Available methods are those associated with interp1 i.e.: 'linear',
% 'nearest', 'next', 'previous', 'spline', 'pchip' (default), 'cubic'.
% Alternatively interpPar my be set as a scalar in the range 0-1 to use the
% csaps method for cubic spline based smoothening.
% 
% See also: interp1, csaps
%
% Kevin Mattheus Moerman
% gibbon.toolbox@gmail.com
% 
% 11/07/2013: Created
% 2013-2015: No log
% 2015/05/05: Improved csaps based smoothening
% 2015/05/05: Updated help and documentation
% 2018/10/15: Added additional resampling for non-linear methods
%------------------------------------------------------------------------

%% Parse input

switch nargin
    case 1
        V=varargin{1};
        n=size(V,1);
        interpPar='pchip';
        closeLoopOpt=0;
    case 2
        V=varargin{1};
        n=varargin{2};
        interpPar='pchip';
        closeLoopOpt=0;
    case 3
        V=varargin{1};
        n=varargin{2};
        interpPar=varargin{3};
        closeLoopOpt=0;
    case 4
        V=varargin{1};
        n=varargin{2};
        interpPar=varargin{3};
        closeLoopOpt=varargin{4};
    otherwise
        error('Wrong number of input arguments');
end

if isempty(interpPar)
     interpPar='pchip';
end

if isempty(n)
     n=size(V,1);
end

if isempty(closeLoopOpt)
     closeLoopOpt=0;
end

%% 
n_in=n;

sizV=size(V);
if closeLoopOpt==1
    n=n+1;
    
    V=[V;V(1,:)]; %Close loop by adding start to end
    
    midInd=round(size(V,1)/2);
    
    %Close loop and aid periodicity by adding start and end points
    V_addBefore=V(midInd:end-1,:);
    V_addAfter=V(2:midInd,:);
    V=[V_addBefore; V; V_addAfter];
    
    startInd=1+size(V_addBefore,1);
    endInd=sizV(1)+size(V_addBefore,1)+1;
    
else
    startInd=1;
    endInd=size(V,1);
end

%Compute distance metric used for parametric representation
D=pathLength(V);

%Redefine distance metric for evenly spaced points
Dg=linspace(D(startInd),D(endInd),n)';

%Interpolate required x values for even spacing allong curve patch
Vg=zeros(n,size(V,2));

%Interpolate using parametric representation
if ~ischar(interpPar) %CSAPS SMOOTHEN, interpret interpPar as smoothening parameter    
    Vg = csaps(D,V',interpPar,Dg)'; %Smoothened ppform
else %NORMAL METHODS
    for q=1:size(V,2)
        switch interpPar
            case 'biharmonic'
                Vg(:,q)=biharmonicSplineInterpolation(D,V(:,q),Dg);            
            otherwise
                Vg(:,q)=interp1(D,V(:,q),Dg,interpPar);
        end
    end
end

%Trim off end for closed curves
if closeLoopOpt==1
    Vg=Vg(1:end-1,:);
end

%Resample again if needed
switch interpPar
    case {'linear','nearest','next','previous'}
        
    otherwise %Resample again using linear method, non-linear methods may alter shape and point spacing
        [Vg]=evenlySampleCurve(Vg,n_in,'linear',closeLoopOpt);
end
 
%% 
% _*GIBBON footer text*_ 
% 
% License: <https://github.com/gibbonCode/GIBBON/blob/master/LICENSE>
% 
% GIBBON: The Geometry and Image-based Bioengineering add-On. A toolbox for
% image segmentation, image-based modeling, meshing, and finite element
% analysis.
% 
% Copyright (C) 2019  Kevin Mattheus Moerman
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
